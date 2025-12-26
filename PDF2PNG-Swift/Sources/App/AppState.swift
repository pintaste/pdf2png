import SwiftUI
import Combine
import AppKit

/// 应用全局状态管理
@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties

    /// 待转换的 PDF 文件列表
    @Published var pendingFiles: [URL] = []

    /// 转换任务列表
    @Published var tasks: [ConversionTask] = []

    /// 是否正在转换
    @Published var isConverting: Bool = false

    /// 显示文件选择器
    @Published var showFilePicker: Bool = false

    /// 转换设置（从 UserDefaults 加载）
    @Published var settings: ConversionSettings = ConversionSettings.load() {
        didSet {
            settings.save()
        }
    }

    /// 错误信息
    @Published var errorMessage: String?

    /// 显示错误提示
    @Published var showError: Bool = false

    /// 显示覆盖确认对话框
    @Published var showOverwriteConfirm: Bool = false

    /// 将被覆盖的文件列表
    @Published var filesToOverwrite: [String] = []

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let converter = PDFConverter()

    // MARK: - Initialization

    init() {
        setupNotifications()
    }

    // MARK: - Public Methods

    /// 添加文件
    func addFiles(_ urls: [URL]) {
        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        for url in pdfURLs {
            if !pendingFiles.contains(url) {
                pendingFiles.append(url)
            }
        }
    }

    /// 移除文件（按索引）
    func removeFile(at index: Int) {
        guard index < pendingFiles.count else { return }
        pendingFiles.remove(at: index)
    }

    /// 移除文件（按 URL）
    func removeFile(_ url: URL) {
        pendingFiles.removeAll { $0 == url }
    }

    /// 清空文件列表和已完成任务
    func clearFiles() {
        pendingFiles.removeAll()
        // 同时清空非转换中的任务
        if !isConverting {
            tasks.removeAll()
        }
    }

    /// 选择输出目录并开始转换
    func selectOutputAndConvert() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "output.selectFolder")
        panel.message = String(localized: "output.message")

        // 默认定位到第一个输入文件的目录
        if let firstFile = pendingFiles.first {
            panel.directoryURL = firstFile.deletingLastPathComponent()
        }

        if panel.runModal() == .OK, let outputURL = panel.url {
            settings.outputDirectory = outputURL

            // 检查是否有文件将被覆盖
            let existingFiles = checkExistingFiles(outputDir: outputURL)
            if !existingFiles.isEmpty {
                filesToOverwrite = existingFiles
                showOverwriteConfirm = true
            } else {
                Task {
                    await startConversion()
                }
            }
        }
    }

    /// 确认覆盖后开始转换
    func confirmOverwriteAndConvert() {
        filesToOverwrite = []
        Task {
            await startConversion()
        }
    }

    /// 检查将被覆盖的文件
    private func checkExistingFiles(outputDir: URL) -> [String] {
        var existingFiles: [String] = []
        let fileManager = FileManager.default

        for pdfURL in pendingFiles {
            let baseName = pdfURL.deletingPathExtension().lastPathComponent

            // 检查单页情况
            let singlePageURL = outputDir.appendingPathComponent("\(baseName).png")
            if fileManager.fileExists(atPath: singlePageURL.path) {
                existingFiles.append("\(baseName).png")
            }

            // 检查多页文件夹
            let multiPageDir = outputDir.appendingPathComponent(baseName)
            if fileManager.fileExists(atPath: multiPageDir.path) {
                existingFiles.append("\(baseName)/ (文件夹)")
            }
        }

        return existingFiles
    }

    /// 最大并行转换数
    private let maxConcurrentConversions = 3

    /// 开始转换
    func startConversion() async {
        guard !pendingFiles.isEmpty else { return }

        isConverting = true
        isCancelled = false
        tasks.removeAll()

        // 创建任务
        for url in pendingFiles {
            let task = ConversionTask(
                id: UUID(),
                sourceURL: url,
                status: .pending
            )
            tasks.append(task)
        }

        // 清空待转换列表（任务已创建）
        pendingFiles.removeAll()

        // 并行执行转换
        await withTaskGroup(of: Void.self) { group in
            var runningCount = 0
            var taskIndex = 0

            while taskIndex < tasks.count && !isCancelled {
                // 控制并发数
                while runningCount >= maxConcurrentConversions {
                    // 等待一个任务完成
                    await group.next()
                    runningCount -= 1
                }

                guard !isCancelled else { break }

                let currentIndex = taskIndex
                let taskId = tasks[currentIndex].id
                let sourceURL = tasks[currentIndex].sourceURL

                // 标记为转换中
                tasks[currentIndex].status = .converting(progress: 0, currentPage: 0, totalPages: 0)

                runningCount += 1
                taskIndex += 1

                group.addTask { [weak self] in
                    guard let self = self else { return }

                    do {
                        let result = try await self.converter.convert(
                            pdfURL: sourceURL,
                            settings: self.settings
                        ) { [weak self] progressInfo in
                            Task { @MainActor in
                                guard let self = self, !self.isCancelled else { return }
                                if let idx = self.tasks.firstIndex(where: { $0.id == taskId }) {
                                    self.tasks[idx].status = .converting(
                                        progress: progressInfo.progress,
                                        currentPage: progressInfo.currentPage,
                                        totalPages: progressInfo.totalPages
                                    )
                                }
                            }
                        }

                        await MainActor.run {
                            guard !self.isCancelled else { return }
                            if let idx = self.tasks.firstIndex(where: { $0.id == taskId }) {
                                self.tasks[idx].status = .completed(result: result)
                            }
                        }
                    } catch {
                        await MainActor.run {
                            if !self.isCancelled {
                                if let idx = self.tasks.firstIndex(where: { $0.id == taskId }) {
                                    self.tasks[idx].status = .failed(error: error.localizedDescription)
                                }
                            }
                        }
                    }
                }
            }

            // 等待所有剩余任务完成
            for await _ in group {}
        }

        isConverting = false

        // 转换完成后打开输出目录并播放音效（仅在未取消时）
        if !isCancelled {
            // 检查是否有失败的任务
            let hasFailures = tasks.contains { task in
                if case .failed = task.status { return true }
                return false
            }

            if hasFailures {
                playErrorSound()
            } else {
                playCompletionSound()
            }

            if let outputDir = settings.outputDirectory {
                NSWorkspace.shared.open(outputDir)
            }
        }
    }

    /// 取消转换
    private var isCancelled = false

    func cancelConversion() {
        isCancelled = true
        // 同步等待 converter 取消完成
        Task {
            await converter.cancel()
        }
        // 将所有进行中或待处理的任务标记为取消
        for i in tasks.indices {
            switch tasks[i].status {
            case .converting, .pending:
                tasks[i].status = .failed(error: "已取消")
            default:
                break
            }
        }
        isConverting = false
    }

    /// 显示错误
    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .openFiles)
            .compactMap { $0.userInfo?["urls"] as? [URL] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urls in
                self?.addFiles(urls)
            }
            .store(in: &cancellables)
    }

    /// 播放完成音效
    private func playCompletionSound() {
        NSSound(named: .init("Glass"))?.play()
    }

    /// 播放错误音效
    private func playErrorSound() {
        NSSound(named: .init("Basso"))?.play()
    }
}
