import Foundation

/// 应用统一错误类型
enum AppError: LocalizedError {
    // 文件错误
    case fileNotFound(String)
    case invalidFileType(String)
    case fileReadError(String)
    case fileWriteError(String)

    // PDF 错误
    case invalidPDF
    case pdfRenderFailed(String)
    case pdfPageNotFound(Int)

    // 转换错误
    case conversionCancelled
    case conversionFailed(String)

    // 权限错误
    case noWritePermission(String)

    // 设置错误
    case invalidSettings(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "文件不存在: \(path)"
        case .invalidFileType(let ext):
            return "不支持的文件类型: \(ext)"
        case .fileReadError(let reason):
            return "读取文件失败: \(reason)"
        case .fileWriteError(let reason):
            return "写入文件失败: \(reason)"
        case .invalidPDF:
            return "无效的 PDF 文件"
        case .pdfRenderFailed(let reason):
            return "PDF 渲染失败: \(reason)"
        case .pdfPageNotFound(let page):
            return "找不到第 \(page) 页"
        case .conversionCancelled:
            return "转换已取消"
        case .conversionFailed(let reason):
            return "转换失败: \(reason)"
        case .noWritePermission(let path):
            return "没有写入权限: \(path)"
        case .invalidSettings(let reason):
            return "设置无效: \(reason)"
        }
    }

    /// 用户友好的简短描述
    var shortDescription: String {
        switch self {
        case .fileNotFound:
            return "文件不存在"
        case .invalidFileType:
            return "不支持的文件类型"
        case .fileReadError:
            return "读取失败"
        case .fileWriteError:
            return "写入失败"
        case .invalidPDF:
            return "无效的 PDF"
        case .pdfRenderFailed:
            return "渲染失败"
        case .pdfPageNotFound:
            return "页面不存在"
        case .conversionCancelled:
            return "已取消"
        case .conversionFailed:
            return "转换失败"
        case .noWritePermission:
            return "权限不足"
        case .invalidSettings:
            return "设置无效"
        }
    }
}
