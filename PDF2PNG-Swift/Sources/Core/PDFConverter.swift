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
        let actualDPI: Int
        let totalSizeBytes: Int
        let renderTimeMs: Double
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
                return String(localized: "error.fileNotFound").replacingOccurrences(of: "%@", with: path)
            case .invalidPDF:
                return String(localized: "error.invalidPDF")
            case .renderFailed(let reason):
                return String(localized: "error.renderFailed").replacingOccurrences(of: "%@", with: reason)
            case .saveFailed(let reason):
                return String(localized: "error.saveFailed").replacingOccurrences(of: "%@", with: reason)
            case .cancelled:
                return String(localized: "error.conversionCancelled")
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
                throw ConversionError.renderFailed(String(localized: "error.cannotGetPage").replacingOccurrences(of: "%d", with: "1"))
            }
            let outputURL = actualOutputDir.appendingPathComponent("\(baseName).png")
            let (data, dpi) = try await convertPage(page: page, settings: settings)
            try data.write(to: outputURL)
            progress(ProgressInfo(currentPage: 1, totalPages: 1, progress: 1.0))
            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            return ConversionResult(outputURLs: [outputURL], actualDPI: dpi, totalSizeBytes: data.count, renderTimeMs: elapsed)
        }

        // 多页并行处理（每页独立计算 DPI）
        var results: [(index: Int, url: URL, size: Int, dpi: Int)] = []
        var completedCount = 0

        try await withThrowingTaskGroup(of: (Int, URL, Int, Int).self) { group in
            for pageIndex in 0..<pageCount {
                guard !isCancelled else { break }

                group.addTask { [self] in
                    guard let page = pdfDocument.page(at: pageIndex) else {
                        throw ConversionError.renderFailed(String(localized: "error.cannotGetPage").replacingOccurrences(of: "%d", with: "\(pageIndex + 1)"))
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
        // 返回 DPI 范围（最小值）
        let minDPI = results.map { $0.dpi }.min() ?? settings.maxDPI
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        return ConversionResult(
            outputURLs: outputURLs,
            actualDPI: minDPI,
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
            let maxSizeBytes = Int(settings.maxSizeMB * 1024 * 1024)

            // 质量优先模式
            if settings.qualityFirst {
                let data = try self.renderPage(page: page, dpi: settings.maxDPI)
                return (data, settings.maxDPI)
            }

            // 大小限制模式
            var resultData = try self.renderPage(page: page, dpi: settings.maxDPI)
            var currentDPI = settings.maxDPI

            // 如果最高 DPI 满足要求
            if resultData.count <= maxSizeBytes {
                return (resultData, currentDPI)
            }

            // 渐进式降低 DPI
            var safety = 0.95
            for _ in 0..<3 {
                let ratio = Double(maxSizeBytes) / Double(resultData.count)
                currentDPI = max(settings.minDPI, Int(Double(currentDPI) * sqrt(ratio) * safety))

                resultData = try self.renderPage(page: page, dpi: currentDPI)

                if resultData.count <= maxSizeBytes {
                    break
                }
                safety *= 0.95
            }

            // 二分法精调
            if resultData.count > maxSizeBytes && currentDPI > settings.minDPI {
                var lowDPI = settings.minDPI
                var highDPI = currentDPI

                while highDPI - lowDPI > 5 {
                    let midDPI = (lowDPI + highDPI) / 2
                    let midData = try self.renderPage(page: page, dpi: midDPI)

                    if midData.count <= maxSizeBytes {
                        lowDPI = midDPI
                        resultData = midData
                        currentDPI = midDPI
                    } else {
                        highDPI = midDPI
                    }
                }
            }

            // 向上逼近（如果文件太小）
            if resultData.count < Int(Double(maxSizeBytes) * 0.9) && currentDPI < settings.maxDPI {
                var bestData = resultData
                var bestDPI = currentDPI

                var lowDPI = currentDPI
                var highDPI = min(Int(Double(currentDPI) * 1.15), settings.maxDPI)

                while highDPI - lowDPI > 15 {  // 放宽精度到 15 DPI
                    let midDPI = (lowDPI + highDPI) / 2
                    let midData = try self.renderPage(page: page, dpi: midDPI)

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

            // 第五步：最终强制验证（绝不超限）
            var finalSize = resultData.count
            if finalSize > maxSizeBytes {
                // 强制使用 min_dpi
                resultData = try self.renderPage(page: page, dpi: settings.minDPI)
                currentDPI = settings.minDPI
                finalSize = resultData.count

                // 应急降档（如 min_dpi 仍超限）
                var emergencyDPI = settings.minDPI
                while finalSize > maxSizeBytes && emergencyDPI > ConversionSettings.emergencyMinDPI {
                    emergencyDPI = Int(Double(emergencyDPI) * 0.8)
                    resultData = try self.renderPage(page: page, dpi: emergencyDPI)
                    finalSize = resultData.count
                    currentDPI = emergencyDPI
                }
            }

            return (resultData, currentDPI)
        }.value
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
            throw ConversionError.renderFailed(String(localized: "error.cannotCreateContext"))
        }

        // 白色背景
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // 缩放并渲染
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)

        // 获取图像
        guard let cgImage = context.makeImage() else {
            throw ConversionError.renderFailed(String(localized: "error.cannotGenerateImage"))
        }

        // 转换为 PNG
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ConversionError.renderFailed(String(localized: "error.cannotGeneratePNG"))
        }

        return pngData
    }
}
