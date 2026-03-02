import Foundation

/// 转换任务
struct ConversionTask: Identifiable {
    let id: UUID
    let sourceURL: URL
    var status: TaskStatus
    let fileSizeFormatted: String  // 存储属性，避免重复 I/O

    /// 文件名
    var fileName: String {
        sourceURL.lastPathComponent
    }

    /// 初始化方法
    init(id: UUID, sourceURL: URL, status: TaskStatus) {
        self.id = id
        self.sourceURL = sourceURL
        self.status = status

        // 在初始化时计算文件大小（仅一次）
        if let attrs = try? FileManager.default.attributesOfItem(atPath: sourceURL.path),
           let size = attrs[.size] as? Int64 {
            self.fileSizeFormatted = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        } else {
            self.fileSizeFormatted = String(localized: "error.unknown", bundle: .module)
        }
    }
}

/// 任务状态
enum TaskStatus {
    case pending
    case converting(progress: Double, currentPage: Int, totalPages: Int)
    case completed(result: PDFConverter.ConversionResult)
    case failed(error: String)
    case cancelled

    /// 是否完成
    var isCompleted: Bool {
        switch self {
        case .completed, .failed, .cancelled:
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
        case .completed, .failed, .cancelled:
            return 1
        }
    }

    /// 状态描述
    var description: String {
        switch self {
        case .pending:
            return String(localized: "status.pending", bundle: .module)
        case .converting(_, let currentPage, let totalPages):
            if totalPages > 1 {
                return String(localized: "status.page", bundle: .module)
                    .replacingOccurrences(of: "%d/%d", with: "\(currentPage)/\(totalPages)")
            } else {
                return String(localized: "status.converting", bundle: .module)
            }
        case .completed(let result):
            let size = ByteCountFormatter.string(fromByteCount: Int64(result.totalSizeBytes), countStyle: .file)
            let timeStr = formatTime(result.renderTimeMs)
            return "\(String(localized: "status.completed", bundle: .module)) (\(size), \(result.dpiDisplay)DPI, \(timeStr))"
        case .failed(let error):
            return "\(String(localized: "status.failed", bundle: .module)): \(error)"
        case .cancelled:
            return String(localized: "status.cancelled", bundle: .module)
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
