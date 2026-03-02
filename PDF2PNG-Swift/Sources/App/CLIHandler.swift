import Foundation
import AppKit
import PDFKit

/// CLI 模式处理器
actor CLIHandler {
    static func run() async {
        let args = CommandLine.arguments

        // 显示使用说明
        if args.contains("-h") || args.contains("--help") {
            printHelp()
            return
        }

        // 解析参数
        guard let pdfPath = args.first(where: { $0.hasSuffix(".pdf") }) else {
            print("❌ 错误: 未指定 PDF 文件")
            print("使用 --help 查看帮助")
            exit(1)
        }

        let pdfURL = URL(fileURLWithPath: pdfPath)

        // 解析设置
        var settings = ConversionSettings.default

        if let maxDPIIndex = args.firstIndex(of: "--max-dpi"),
           maxDPIIndex + 1 < args.count,
           let maxDPI = Int(args[maxDPIIndex + 1]) {
            settings.maxDPI = maxDPI
        }

        if let minDPIIndex = args.firstIndex(of: "--min-dpi"),
           minDPIIndex + 1 < args.count,
           let minDPI = Int(args[minDPIIndex + 1]) {
            settings.minDPI = minDPI
        }

        if let maxSizeIndex = args.firstIndex(of: "--max-size"),
           maxSizeIndex + 1 < args.count,
           let maxSize = Double(args[maxSizeIndex + 1]) {
            settings.maxSizeMB = maxSize
        }

        if args.contains("--quality-first") {
            settings.qualityFirst = true
        }

        if let outputDirIndex = args.firstIndex(of: "--output"),
           outputDirIndex + 1 < args.count {
            settings.outputDirectory = URL(fileURLWithPath: args[outputDirIndex + 1])
        }

        // 显示配置
        print("📋 转换配置:")
        print("  输入文件: \(pdfURL.path)")
        print("  模式: \(settings.qualityFirst ? "质量优先" : "大小限制")")
        if settings.qualityFirst {
            print("  DPI: \(settings.maxDPI)")
        } else {
            print("  大小限制: \(settings.maxSizeMB) MB")
            print("  DPI 范围: \(settings.minDPI) - \(settings.maxDPI)")
        }
        print("  输出目录: \(settings.outputDirectory?.path ?? "与源文件相同")")
        print("")

        // 执行转换
        let converter = PDFConverter()

        do {
            print("🚀 开始转换...")
            let result = try await converter.convert(
                pdfURL: pdfURL,
                settings: settings,
                progress: { info in
                    let percentage = Int(info.progress * 100)
                    print("  进度: \(info.currentPage)/\(info.totalPages) (\(percentage)%)")
                }
            )

            print("")
            print("✅ 转换成功!")
            print("  输出文件数: \(result.outputURLs.count)")
            print("  DPI 范围: \(result.dpiDisplay)")
            print("  总大小: \(formatBytes(result.totalSizeBytes))")
            print("  渲染时间: \(String(format: "%.2f", result.renderTimeMs)) ms")
            print("")
            print("📁 输出文件:")
            for url in result.outputURLs {
                if let size = fileSize(url: url) {
                    print("  - \(url.lastPathComponent) (\(formatBytes(size)))")
                }
            }

            exit(0)

        } catch let error as PDFConverter.ConversionError {
            print("")
            print("❌ 转换失败: \(error.localizedDescription)")
            exit(1)

        } catch {
            print("")
            print("❌ 未知错误: \(error)")
            exit(1)
        }
    }

    static func printHelp() {
        print("""
        PDF2PNG - PDF 到 PNG 高清转换工具 (CLI 模式)

        用法:
          PDF2PNG <pdf文件> [选项]

        选项:
          --quality-first           质量优先模式（使用最高 DPI）
          --max-dpi <值>            最大 DPI (默认: 600)
          --min-dpi <值>            最小 DPI (默认: 150, 仅大小限制模式)
          --max-size <MB>           文件大小限制 (默认: 5 MB, 仅大小限制模式)
          --output <目录>           输出目录 (默认: 与源文件相同)
          -h, --help                显示此帮助信息

        示例:
          # 质量优先模式，600 DPI
          PDF2PNG test.pdf --quality-first --max-dpi 600

          # 大小限制模式，5 MB 限制
          PDF2PNG test.pdf --max-size 5

          # 自定义 DPI 范围
          PDF2PNG test.pdf --max-size 10 --min-dpi 200 --max-dpi 800

          # 指定输出目录
          PDF2PNG test.pdf --output ~/Downloads

        注意:
          - 默认使用大小限制模式 (5 MB)
          - 大小限制模式会自动调整 DPI 以满足文件大小要求
          - 多页 PDF 会创建子目录存放所有页面
        """)
    }

    static func fileSize(url: URL) -> Int? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return Int(size)
    }

    static func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024

        if mb >= 1 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }
}
