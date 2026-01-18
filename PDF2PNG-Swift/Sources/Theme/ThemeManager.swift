import SwiftUI
import AppKit

/// 主题管理器 - 控制深色/浅色模式切换
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var isDarkMode: Bool = true
    @Published var isManualOverride: Bool = false  // 是否手动覆盖

    init() {
        // 检测系统主题
        updateTheme()

        // 监听系统主题变化
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    @objc private func systemThemeChanged() {
        DispatchQueue.main.async {
            if !self.isManualOverride {
                self.updateTheme()
            }
        }
    }

    private func updateTheme() {
        if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) {
            isDarkMode = appearance == .darkAqua
        }
    }

    /// 手动切换主题
    func toggleTheme() {
        isManualOverride = true
        isDarkMode.toggle()
    }
}
