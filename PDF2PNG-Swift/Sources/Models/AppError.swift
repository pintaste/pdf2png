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
            return String(localized: "appError.fileNotFound", bundle: .module).replacingOccurrences(of: "%@", with: path)
        case .invalidFileType(let ext):
            return String(localized: "appError.invalidFileType", bundle: .module).replacingOccurrences(of: "%@", with: ext)
        case .fileReadError(let reason):
            return String(localized: "appError.fileReadError", bundle: .module).replacingOccurrences(of: "%@", with: reason)
        case .fileWriteError(let reason):
            return String(localized: "appError.fileWriteError", bundle: .module).replacingOccurrences(of: "%@", with: reason)
        case .invalidPDF:
            return String(localized: "appError.short.invalidPDF", bundle: .module)
        case .pdfRenderFailed(let reason):
            return String(localized: "appError.pdfRenderFailed", bundle: .module).replacingOccurrences(of: "%@", with: reason)
        case .pdfPageNotFound(let page):
            return String(localized: "appError.pdfPageNotFound", bundle: .module).replacingOccurrences(of: "%d", with: "\(page)")
        case .conversionCancelled:
            return String(localized: "status.cancelled", bundle: .module)
        case .conversionFailed(let reason):
            return String(localized: "appError.conversionFailed", bundle: .module).replacingOccurrences(of: "%@", with: reason)
        case .noWritePermission(let path):
            return String(localized: "appError.noWritePermission", bundle: .module).replacingOccurrences(of: "%@", with: path)
        case .invalidSettings(let reason):
            return String(localized: "appError.invalidSettings", bundle: .module).replacingOccurrences(of: "%@", with: reason)
        }
    }

    /// 用户友好的简短描述
    var shortDescription: String {
        switch self {
        case .fileNotFound:
            return String(localized: "appError.short.fileNotFound", bundle: .module)
        case .invalidFileType:
            return String(localized: "appError.short.invalidFileType", bundle: .module)
        case .fileReadError:
            return String(localized: "appError.short.fileReadError", bundle: .module)
        case .fileWriteError:
            return String(localized: "appError.short.fileWriteError", bundle: .module)
        case .invalidPDF:
            return String(localized: "appError.short.invalidPDF", bundle: .module)
        case .pdfRenderFailed:
            return String(localized: "appError.short.pdfRenderFailed", bundle: .module)
        case .pdfPageNotFound:
            return String(localized: "appError.short.pdfPageNotFound", bundle: .module)
        case .conversionCancelled:
            return String(localized: "appError.short.conversionCancelled", bundle: .module)
        case .conversionFailed:
            return String(localized: "appError.short.conversionFailed", bundle: .module)
        case .noWritePermission:
            return String(localized: "appError.short.noWritePermission", bundle: .module)
        case .invalidSettings:
            return String(localized: "appError.short.invalidSettings", bundle: .module)
        }
    }
}
