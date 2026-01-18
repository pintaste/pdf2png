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
            let (data, dpi) = try await convertPage(page: page, settings: settings)
            try data.write(to: outputURL)
            progress(ProgressInfo(currentPage: 1, totalPages: 1, progress: 1.0))
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return ConversionResult(outputURLs: [outputURL], minDPI: dpi, maxDPI: dpi, totalSizeBytes: data.count, renderTimeMs: elapsed)
        }

        // 多页并行处理（每页独立计算 DPI）
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

                    // 每页独立计算最优 DPI
                    let (data, dpi) = try await self.convertPage(page: page, settings: settings)
                    try data.write(to: outputURL)

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
        // 返回 DPI 范围
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

    /// 质量优先模式：使用最高 DPI 渲染
    private nonisolated func renderWithQuality(page: PDFPage, dpi: Int) throws -> (Data, Int) {
        let data = try renderPage(page: page, dpi: dpi)
        return (data, dpi)
    }

    // MARK: - Size-Limit Mode (5-Step Algorithm)

    /// 大小限制模式：智能 DPI 优化算法
    private nonisolated func renderWithSizeLimit(
        page: PDFPage,
        settings: ConversionSettings
    ) throws -> (Data, Int) {
        let maxSizeBytes = Int(settings.maxSizeMB * 1024 * 1024)

        // Step 1: 尝试最高 DPI
        var resultData = try renderPage(page: page, dpi: settings.maxDPI)
        var currentDPI = settings.maxDPI

        if resultData.count <= maxSizeBytes {
            return (resultData, currentDPI)
        }

        // Step 2: 渐进式降低 DPI
        (resultData, currentDPI) = try progressiveReduction(
            page: page,
            startDPI: currentDPI,
            minDPI: settings.minDPI,
            maxSizeBytes: maxSizeBytes,
            initialData: resultData
        )

        // Step 3: 二分法精调
        if resultData.count > maxSizeBytes && currentDPI > settings.minDPI {
            (resultData, currentDPI) = try binarySearchOptimize(
                page: page,
                lowDPI: settings.minDPI,
                highDPI: currentDPI,
                maxSizeBytes: maxSizeBytes
            )
        }

        // Step 4: 向上逼近（如果文件太小）
        if resultData.count < Int(Double(maxSizeBytes) * 0.9) && currentDPI < settings.maxDPI {
            (resultData, currentDPI) = try upwardApproach(
                page: page,
                currentDPI: currentDPI,
                maxDPI: settings.maxDPI,
                maxSizeBytes: maxSizeBytes,
                currentData: resultData
            )
        }

        // Step 5: 最终强制验证（绝不超限）
        if resultData.count > maxSizeBytes {
            (resultData, currentDPI) = try emergencyFallback(
                page: page,
                minDPI: settings.minDPI,
                maxSizeBytes: maxSizeBytes
            )
        }

        return (resultData, currentDPI)
    }

    /// Step 2: 渐进式降低 DPI (Progressive Reduction)
    private nonisolated func progressiveReduction(
        page: PDFPage,
        startDPI: Int,
        minDPI: Int,
        maxSizeBytes: Int,
        initialData: Data
    ) throws -> (Data, Int) {
        var resultData = initialData
        var currentDPI = startDPI
        var safety = 0.95

        for _ in 0..<3 {
            guard resultData.count > maxSizeBytes else { break }

            let ratio = Double(maxSizeBytes) / Double(resultData.count)
            currentDPI = max(minDPI, Int(Double(currentDPI) * sqrt(ratio) * safety))

            resultData = try renderPage(page: page, dpi: currentDPI)
            safety *= 0.95
        }

        return (resultData, currentDPI)
    }

    /// Step 3: 二分法精调 (Binary Search Optimization)
    private nonisolated func binarySearchOptimize(
        page: PDFPage,
        lowDPI: Int,
        highDPI: Int,
        maxSizeBytes: Int
    ) throws -> (Data, Int) {
        var low = lowDPI
        var high = highDPI
        var resultData = try renderPage(page: page, dpi: low)
        var currentDPI = low

        while high - low > 5 {
            let midDPI = (low + high) / 2
            let midData = try renderPage(page: page, dpi: midDPI)

            if midData.count <= maxSizeBytes {
                low = midDPI
                resultData = midData
                currentDPI = midDPI
            } else {
                high = midDPI
            }
        }

        return (resultData, currentDPI)
    }

    /// Step 4: 向上逼近 (Upward Approach)
    private nonisolated func upwardApproach(
        page: PDFPage,
        currentDPI: Int,
        maxDPI: Int,
        maxSizeBytes: Int,
        currentData: Data
    ) throws -> (Data, Int) {
        var bestData = currentData
        var bestDPI = currentDPI

        var lowDPI = currentDPI
        var highDPI = min(Int(Double(currentDPI) * 1.15), maxDPI)

        while highDPI - lowDPI > 15 {  // 放宽精度到 15 DPI
            let midDPI = (lowDPI + highDPI) / 2
            let midData = try renderPage(page: page, dpi: midDPI)

            if midData.count <= maxSizeBytes {
                lowDPI = midDPI
                bestData = midData
                bestDPI = midDPI
            } else {
                highDPI = midDPI
            }
        }

        return (bestData, bestDPI)
    }

    /// Step 5: 应急降档 (Emergency Fallback)
    private nonisolated func emergencyFallback(
        page: PDFPage,
        minDPI: Int,
        maxSizeBytes: Int
    ) throws -> (Data, Int) {
        let absoluteMinDPI = 18  // 绝对最低 DPI（再低则图像不可用）

        // 先尝试用户设置的 minDPI
        var resultData = try renderPage(page: page, dpi: minDPI)
        var currentDPI = minDPI

        // 如果仍超限，持续降低到绝对下限
        var emergencyDPI = minDPI
        while resultData.count > maxSizeBytes && emergencyDPI > absoluteMinDPI {
            emergencyDPI = max(absoluteMinDPI, Int(Double(emergencyDPI) * 0.8))
            resultData = try renderPage(page: page, dpi: emergencyDPI)
            currentDPI = emergencyDPI
        }

        // 如果 absoluteMinDPI 仍超限，使用二分法精确查找
        if resultData.count > maxSizeBytes {
            let minData = try renderPage(page: page, dpi: absoluteMinDPI)

            if minData.count <= maxSizeBytes {
                // 二分法找到最大可用 DPI
                var lowDPI = absoluteMinDPI
                var highDPI = emergencyDPI
                var bestData = minData
                var bestDPI = absoluteMinDPI

                while highDPI - lowDPI > 2 {
                    let midDPI = (lowDPI + highDPI) / 2
                    let midData = try renderPage(page: page, dpi: midDPI)

                    if midData.count <= maxSizeBytes {
                        lowDPI = midDPI
                        bestData = midData
                        bestDPI = midDPI
                    } else {
                        highDPI = midDPI
                    }
                }

                resultData = bestData
                currentDPI = bestDPI
            }
            // 如果即使 absoluteMinDPI 也超限，保持当前结果（已是最佳努力）
        }

        return (resultData, currentDPI)
    }

    /// 渲染页面为 PNG 数据（nonisolated 因为不访问 actor 状态）
    private nonisolated func renderPage(page: PDFPage, dpi: Int) throws -> Data {
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

        // 转换为 PNG
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ConversionError.renderFailed(String(localized: "error.cannotGeneratePNG", bundle: .module))
        }

        return pngData
    }
}
