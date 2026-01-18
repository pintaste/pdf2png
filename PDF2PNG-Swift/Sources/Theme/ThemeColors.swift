import SwiftUI

/// 主题颜色配置
struct ThemeColors {
    @Environment(\.colorScheme) static var colorScheme

    // 判断是否为深色模式
    static var isDark: Bool {
        ThemeManager.shared.isDarkMode
    }

    // 主色调
    static var backgroundPrimary: Color {
        isDark ? Color(hex: "#302723") : Color(hex: "#f5f0eb")
    }
    static var backgroundSecondary: Color {
        isDark ? Color(hex: "#3d322e") : Color(hex: "#e8e0d8")
    }
    static var backgroundTertiary: Color {
        isDark ? Color(hex: "#4a3f3a") : Color(hex: "#ddd5cd")
    }
    static var backgroundInput: Color {
        isDark ? Color(hex: "#252019") : Color(hex: "#ffffff")
    }

    // 边框
    static var borderNormal: Color {
        isDark ? Color(hex: "#5a4f4a") : Color(hex: "#c0b5a8")
    }
    static var borderHover: Color {
        isDark ? Color(hex: "#6a5f5a") : Color(hex: "#a09588")
    }

    // 文字
    static var textPrimary: Color {
        isDark ? Color.white : Color(hex: "#333333")
    }
    static var textSecondary: Color {
        isDark ? Color(hex: "#e0d5d0") : Color(hex: "#555555")
    }
    static var textMuted: Color {
        isDark ? Color(hex: "#c0b5b0") : Color(hex: "#777777")
    }

    // 强调色
    static let accent = Color(hex: "#ffd34d")
    static let accentHover = Color(hex: "#FFE082")

    // 选择器强调色 - 浅色模式用深色以增加对比度
    static var pickerAccent: Color {
        isDark ? Color(hex: "#ffd34d") : Color(hex: "#d4a017")
    }

    // 文件图标色
    static var fileIcon: Color {
        isDark ? Color(hex: "#ffd34d") : Color(hex: "#555555")
    }

    // 状态色（用于图标）
    static let success = Color(hex: "#4ade80")
    static let error = Color(hex: "#ef4444")

    // 状态文字色（低饱和度，易读）
    static var statusTextSuccess: Color {
        isDark ? Color(hex: "#86c794") : Color(hex: "#3d7a4a")
    }
    static var statusTextError: Color {
        isDark ? Color(hex: "#d88888") : Color(hex: "#b54545")
    }
    static var statusTextProgress: Color {
        isDark ? Color(hex: "#d4b56a") : Color(hex: "#a08030")
    }
}
