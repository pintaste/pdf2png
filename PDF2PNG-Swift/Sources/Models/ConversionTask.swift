import Foundation

/// 转换任务
struct ConversionTask: Identifiable {
    let id: UUID
    let sourceURL: URL
    var status: TaskStatus

    /// 文件名
    var fileName: String {
        sourceURL.lastPathComponent
    }

    /// 文件大小（格式化）
    var fileSizeFormatted: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: sourceURL.path),
              let size = attrs[.size] as? Int64 else {
            return "未知"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// 任务状态
enum TaskStatus {
    case pending
    case converting(progress: Double, currentPage: Int, totalPages: Int)
    case completed(result: PDFConverter.ConversionResult)
    case failed(error: String)

    /// 是否完成
    var isCompleted: Bool {
        switch self {
        case .completed, .failed:
            return true
        default:
            return false
        }
    }

    /// 进度值 (0-1)
    var progress: Double {
        switch self {
        case .pending:
            return 0
        case .converting(let progress, _, _):
            return progress
        case .completed, .failed:
            return 1
        }
    }

    /// 状态描述
    var description: String {
        switch self {
        case .pending:
            return "等待中"
        case .converting(_, let currentPage, let totalPages):
            if totalPages > 1 {
                return "转换中 \(currentPage)/\(totalPages) 页"
            } else {
                return "转换中..."
            }
        case .completed(let result):
            let size = ByteCountFormatter.string(fromByteCount: Int64(result.totalSizeBytes), countStyle: .file)
            let timeStr = formatTime(result.renderTimeMs)
            return "完成 (\(size), \(result.actualDPI)DPI, \(timeStr))"
        case .failed(let error):
            return "失败: \(error)"
        }
    }

    /// 格式化时间
    private func formatTime(_ ms: Double) -> String {
        if ms < 1000 {
            return "\(Int(ms))ms"
        } else {
            return String(format: "%.1fs", ms / 1000)
        }
    }
}
