import Foundation

/// 转换设置
struct ConversionSettings: Codable {
    // MARK: - Constants

    static let minAllowedDPI = 72
    static let maxAllowedDPI = 2400
    static let emergencyMinDPI = 36  // 应急模式绝对下限
    static let minAllowedSizeMB = 0.5
    static let maxAllowedSizeMB = 100.0

    // MARK: - Properties

    /// 最大文件大小（MB）
    var maxSizeMB: Double {
        didSet {
            maxSizeMB = max(Self.minAllowedSizeMB, min(Self.maxAllowedSizeMB, maxSizeMB))
        }
    }

    /// 最小 DPI
    var minDPI: Int {
        didSet {
            minDPI = max(Self.minAllowedDPI, min(maxDPI, minDPI))
        }
    }

    /// 最大 DPI
    var maxDPI: Int {
        didSet {
            maxDPI = max(minDPI, min(Self.maxAllowedDPI, maxDPI))
        }
    }

    /// 质量优先模式（忽略大小限制）
    var qualityFirst: Bool

    /// 输出目录（nil 表示与源文件相同目录）
    var outputDirectory: URL?

    // MARK: - Validation

    /// 验证设置是否有效
    var isValid: Bool {
        return minDPI >= Self.minAllowedDPI &&
               maxDPI <= Self.maxAllowedDPI &&
               minDPI <= maxDPI &&
               maxSizeMB >= Self.minAllowedSizeMB &&
               maxSizeMB <= Self.maxAllowedSizeMB
    }

    /// 修正无效设置
    mutating func validate() {
        maxSizeMB = max(Self.minAllowedSizeMB, min(Self.maxAllowedSizeMB, maxSizeMB))
        minDPI = max(Self.minAllowedDPI, minDPI)
        maxDPI = min(Self.maxAllowedDPI, maxDPI)
        if minDPI > maxDPI {
            minDPI = maxDPI
        }
    }

    /// 默认设置
    static let `default` = ConversionSettings(
        maxSizeMB: 5.0,
        minDPI: 150,
        maxDPI: 600,
        qualityFirst: false,
        outputDirectory: nil
    )

    /// 高质量设置
    static let highQuality = ConversionSettings(
        maxSizeMB: 10.0,
        minDPI: 300,
        maxDPI: 1200,
        qualityFirst: true,
        outputDirectory: nil
    )

    /// DPI 预设
    enum DPIPreset: String, CaseIterable, Identifiable {
        case standard = "标准 (600 DPI)"
        case high = "高清 (1200 DPI)"
        case ultra = "超高清 (2400 DPI)"
        case custom = "自定义"

        var id: String { rawValue }

        var maxDPI: Int {
            switch self {
            case .standard: return 600
            case .high: return 1200
            case .ultra: return 2400
            case .custom: return 600
            }
        }
    }

    /// 大小限制预设
    enum SizePreset: String, CaseIterable, Identifiable {
        case small = "小 (2 MB)"
        case medium = "中 (5 MB)"
        case large = "大 (10 MB)"
        case unlimited = "无限制"

        var id: String { rawValue }

        var maxSizeMB: Double {
            switch self {
            case .small: return 2.0
            case .medium: return 5.0
            case .large: return 10.0
            case .unlimited: return Double.infinity
            }
        }

        var qualityFirst: Bool {
            self == .unlimited
        }
    }
}

// MARK: - UserDefaults 存储

extension ConversionSettings {
    private static let userDefaultsKey = "ConversionSettings"

    /// 从 UserDefaults 加载
    static func load() -> ConversionSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              var settings = try? JSONDecoder().decode(ConversionSettings.self, from: data) else {
            return .default
        }
        // 验证并修正加载的设置
        settings.validate()
        return settings
    }

    /// 保存到 UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}
