import Foundation
import PDFKit
import AppKit
import CoreGraphics

/// PDF 到 PNG 转换器
actor PDFConverter {
    // MARK: - Types

    /// 转换结果
    struct ConversionResult {
        let outputURLs: [URL]
        let minDPI: Int      // 最低使用的 DPI
        let maxDPI: Int      // 最高使用的 DPI
        let totalSizeBytes: Int
        let renderTimeMs: Double

        /// 兼容性：返回 DPI 显示字符串
        var dpiDisplay: String {
            if minDPI == maxDPI {
                return "\(minDPI)"
            } else {
                return "\(minDPI)-\(maxDPI)"
            }
        }
    }

    /// 转换错误
    enum ConversionError: LocalizedError {
        case fileNotFound(String)
        case invalidPDF
        case renderFailed(String)
        case saveFailed(String)
        case cancelled
        case sizeLimitExceeded(currentSizeMB: Double, limitMB: Double, minDPI: Int)
        case minDPIConflict(minDPI: Int, minDPISizeMB: Double, limitMB: Double, suggestion: String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return String(localized: "error.fileNotFound", bundle: .module).replacingOccurrences(of: "%@", with: path)
            case .invalidPDF:
                return String(localized: "error.invalidPDF", bundle: .module)
            case .renderFailed(let reason):
                return String(localized: "error.renderFailed", bundle: .module).replacingOccurrences(of: "%@", with: reason)
            case .saveFailed(let reason):
                return String(localized: "error.saveFailed", bundle: .module).replacingOccurrences(of: "%@", with: reason)
            case .cancelled:
                return String(localized: "error.conversionCancelled", bundle: .module)
            case .sizeLimitExceeded(let currentSizeMB, let limitMB, let minDPI):
                return "无法将文件压缩到 \(String(format: "%.1f", limitMB)) MB 以内。当前大小: \(String(format: "%.1f", currentSizeMB)) MB (已使用最低 DPI: \(minDPI))。请提高大小限制或降低 DPI 范围。"
            case .minDPIConflict(let minDPI, let sizeMB, let limitMB, let suggestion):
                return """
最小 DPI 设置与文件大小限制冲突

您设置的最小 DPI (\(minDPI)) 生成的文件大小为 \(String(format: "%.2f", sizeMB)) MB
超过了您设置的文件大小限制 \(String(format: "%.2f", limitMB)) MB

\(suggestion)
"""
            }
        }
    }

    // MARK: - Properties

    private var isCancelled = false
    private static let pdfBaseDPI: CGFloat = 72.0

    // MARK: - Public Methods

    /// 进度信息
    struct ProgressInfo {
        let currentPage: Int
        let totalPages: Int
        let progress: Double
    }

    /// 最大并行页面数
    private static let maxConcurrentPages = 4

    /// 转换 PDF 到 PNG
    func convert(
        pdfURL: URL,
        settings: ConversionSettings,
        progress: @escaping (ProgressInfo) -> Void
    ) async throws -> ConversionResult {
        isCancelled = false

        // 验证文件
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            throw ConversionError.fileNotFound(pdfURL.path)
        }

        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw ConversionError.invalidPDF
        }

        let pageCount = pdfDocument.pageCount
        let startTime = CFAbsoluteTimeGetCurrent()

        // 确定输出目录
        let outputDir = settings.outputDirectory ?? pdfURL.deletingLastPathComponent()
        let baseName = pdfURL.deletingPathExtension().lastPathComponent

        // 创建输出目录（多页时使用子文件夹）
        let actualOutputDir: URL
        if pageCount > 1 {
            actualOutputDir = outputDir.appendingPathComponent(baseName)
            try? FileManager.default.createDirectory(at: actualOutputDir, withIntermediateDirectories: true)
        } else {
            actualOutputDir = outputDir
        }

        // 单页快速路径
        if pageCount == 1 {
            guard let page = pdfDocument.page(at: 0) else {
                throw ConversionError.renderFailed(String(localized: "error.cannotGetPage", bundle: .module).replacingOccurrences(of: "%d", with: "1"))
            }
            let outputURL = actualOutputDir.appendingPathComponent("\(baseName).png")

            // --- UNIFIED LOGIC ---
            // Directly call convertPage, which contains the correct binary search / quality logic.
            let (data, dpi) = try await convertPage(page: page, settings: settings)
            try data.write(to: outputURL)

            // Verify the output file size if not in quality-first mode
            if !settings.qualityFirst {
                try verifyOutputFileSize(url: outputURL, settings: settings, usedDPI: dpi)
            }

            // Report progress and return result
            progress(ProgressInfo(currentPage: 1, totalPages: 1, progress: 1.0))
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return ConversionResult(outputURLs: [outputURL], minDPI: dpi, maxDPI: dpi, totalSizeBytes: data.count, renderTimeMs: elapsed)
            // --- END UNIFIED LOGIC ---
        }

        // 多页文件：每页独立计算最优 DPI（严格模式）
        var results: [(index: Int, url: URL, size: Int, dpi: Int)] = []
        var completedCount = 0

        try await withThrowingTaskGroup(of: (Int, URL, Int, Int).self) { group in
            for pageIndex in 0..<pageCount {
                guard !isCancelled else { break }

                group.addTask { [self] in
                    guard let page = pdfDocument.page(at: pageIndex) else {
                        throw ConversionError.renderFailed(String(localized: "error.cannotGetPage", bundle: .module).replacingOccurrences(of: "%d", with: "\(pageIndex + 1)"))
                    }

                    let outputURL = actualOutputDir.appendingPathComponent("page\(pageIndex + 1).png")

                    // 每页独立计算最优 DPI（使用严格模式确保不超标）
                    let (data, dpi) = try await self.convertPage(page: page, settings: settings)
                    try data.write(to: outputURL)

                    // 验证每页输出文件大小（质量优先模式跳过）
                    if !settings.qualityFirst {
                        try self.verifyOutputFileSize(url: outputURL, settings: settings, usedDPI: dpi)
                    }

                    return (pageIndex, outputURL, data.count, dpi)
                }
            }

            for try await result in group {
                guard !isCancelled else {
                    throw ConversionError.cancelled
                }
                results.append(result)

                // 更新进度
                completedCount += 1
                let progressValue = Double(completedCount) / Double(pageCount)
                progress(ProgressInfo(currentPage: completedCount, totalPages: pageCount, progress: progressValue))
            }
        }

        guard !isCancelled else {
            throw ConversionError.cancelled
        }

        // 按页面顺序排序
        results.sort { $0.index < $1.index }

        let outputURLs = results.map { $0.url }
        let totalSize = results.reduce(0) { $0 + $1.size }

        // 统计 DPI 范围
        let dpiValues = results.map { $0.dpi }
        let resultMinDPI = dpiValues.min() ?? settings.maxDPI
        let resultMaxDPI = dpiValues.max() ?? settings.maxDPI

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        return ConversionResult(
            outputURLs: outputURLs,
            minDPI: resultMinDPI,
            maxDPI: resultMaxDPI,
            totalSizeBytes: totalSize,
            renderTimeMs: elapsed
        )
    }

    /// 取消转换
    func cancel() {
        isCancelled = true
    }

    // MARK: - Private Methods

    /// 验证输出文件大小（保存后的最终检查）
    private nonisolated func verifyOutputFileSize(
        url: URL,
        settings: ConversionSettings,
        usedDPI: Int
    ) throws {
        // 使用 resourceValues - 最可靠的文件大小获取方法
        guard let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = resources.fileSize else {
            throw ConversionError.renderFailed("无法验证文件大小")
        }

        let multiplier = settings.sizeCalculationMode == .safe ? 1_000_000.0 : 1_048_576.0
        let maxSizeBytes = Int64(settings.maxSizeMB * multiplier)
        let fileSizeMB = Double(fileSize) / multiplier

        // 严格验证：文件大小必须 <= 限制
        if Int64(fileSize) > maxSizeBytes {
            // 删除超标文件
            try? FileManager.default.removeItem(at: url)

            // 抛出错误
            throw ConversionError.sizeLimitExceeded(
                currentSizeMB: fileSizeMB,
                limitMB: settings.maxSizeMB,
                minDPI: usedDPI
            )
        }
    }

    /// 转换单个页面（在后台线程执行）
    private func convertPage(
        page: PDFPage,
        settings: ConversionSettings
    ) async throws -> (Data, Int) {
        // 在后台线程执行渲染以避免阻塞
        return try await Task.detached(priority: .userInitiated) { [self] in
            if settings.qualityFirst {
                return try self.renderWithQuality(page: page, dpi: settings.maxDPI)
            } else {
                return try self.renderWithSizeLimit(page: page, settings: settings)
            }
        }.value
    }

    // MARK: - Quality-First Mode

    /// 质量优先模式：使用指定 DPI 渲染，并启用压缩
    /// 核心逻辑：DPI 固定，在保证清晰度不变的情况下启用 PNG 压缩
    private nonisolated func renderWithQuality(page: PDFPage, dpi: Int) throws -> (Data, Int) {
        // ✅ 使用 0.85 压缩系数（1.0 是最大压缩，0.85 平衡质量和大小）
        let data = try renderPage(page: page, dpi: dpi, compression: 0.85)
        return (data, dpi)
    }

    // MARK: - Size-Limit Mode (Strict Binary Search)

    /// 大小限制模式：严格二分查找算法
    /// 确保结果严格小于 maxSizeMB，否则抛出错误
    private nonisolated func renderWithSizeLimit(
        page: PDFPage,
        settings: ConversionSettings
    ) throws -> (Data, Int) {
        let multiplier = settings.sizeCalculationMode == .safe ? 1_000_000.0 : 1_048_576.0
        let maxSizeBytes = Int(settings.maxSizeMB * multiplier)

        // 安全系数：留 3% 缓冲避免 PNG 压缩波动导致超标
        let safeSizeBytes = Int(Double(maxSizeBytes) * 0.97)

        // Step 1: 快速检查最高 DPI
        let maxData = try renderPage(page: page, dpi: settings.maxDPI)
        if maxData.count < safeSizeBytes {
            return (maxData, settings.maxDPI)
        }

        // Step 2: 检查用户设置的最小 DPI 是否可行
        // ✅ 修复：严格遵守用户的 minDPI 设置，不再降到 absoluteMinDPI
        let minData = try renderPage(page: page, dpi: settings.minDPI)
        if minData.count >= safeSizeBytes {
            // 用户的 minDPI 无法满足大小限制，抛出清晰的错误提示
            let currentSizeMB = Double(minData.count) / multiplier
            throw ConversionError.minDPIConflict(
                minDPI: settings.minDPI,
                minDPISizeMB: currentSizeMB,
                limitMB: settings.maxSizeMB,
                suggestion: "请选择：提高文件大小限制到 \(Int(ceil(currentSizeMB))) MB 或 降低最小 DPI"
            )
        }

        // Step 3: 精确二分查找（精度 1 DPI，使用安全阈值）
        var low = settings.minDPI
        var high = settings.maxDPI
        var bestData = minData
        var bestDPI = settings.minDPI

        while high - low > 1 {
            let midDPI = (low + high) / 2
            let midData = try renderPage(page: page, dpi: midDPI)

            if midData.count < safeSizeBytes {
                // 可行，尝试更高 DPI
                low = midDPI
                bestData = midData
                bestDPI = midDPI
            } else {
                // 超标或接近临界值，降低 DPI
                high = midDPI
            }
        }

        // Step 4: 最终强制验证（确保绝对不超过真实限制）
        if bestData.count > maxSizeBytes {
            let currentSizeMB = Double(bestData.count) / multiplier
            throw ConversionError.sizeLimitExceeded(
                currentSizeMB: currentSizeMB,
                limitMB: settings.maxSizeMB,
                minDPI: bestDPI
            )
        }

        return (bestData, bestDPI)
    }

    /// 渲染页面为 PNG 数据（nonisolated 因为不访问 actor 状态）
    /// - Parameters:
    ///   - page: PDF 页面
    ///   - dpi: DPI 值
    ///   - compression: PNG 压缩系数 (0.0-1.0)，0.0=无压缩，1.0=最大压缩
    private nonisolated func renderPage(page: PDFPage, dpi: Int, compression: Double = 0.0) throws -> Data {
        let pageRect = page.bounds(for: .mediaBox)
        let scale = CGFloat(dpi) / Self.pdfBaseDPI

        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)

        // 创建位图上下文
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            throw ConversionError.renderFailed(String(localized: "error.cannotCreateContext", bundle: .module))
        }

        // 白色背景
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // 缩放并渲染
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)

        // 获取图像
        guard let cgImage = context.makeImage() else {
            throw ConversionError.renderFailed(String(localized: "error.cannotGenerateImage", bundle: .module))
        }

        // 转换为 PNG（应用压缩）
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        // ✅ 应用 PNG 压缩（如果 compression > 0）
        let properties: [NSBitmapImageRep.PropertyKey: Any]
        if compression > 0 {
            // 质量优先模式：启用压缩以减小文件大小
            properties = [.compressionFactor: NSNumber(value: compression)]
        } else {
            // 大小限制模式：无压缩，精确控制文件大小
            properties = [:]
        }

        guard let pngData = bitmapRep.representation(using: .png, properties: properties) else {
            throw ConversionError.renderFailed(String(localized: "error.cannotGeneratePNG", bundle: .module))
        }

        return pngData
    }
}
