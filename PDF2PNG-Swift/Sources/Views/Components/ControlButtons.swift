import SwiftUI

// MARK: - macOS Window Control Buttons

struct MacControlButtons: View {
    var body: some View {
        HStack(spacing: 8) {
            // 关闭按钮 - 红色
            Circle()
                .fill(Color(hex: "#ff5f57"))
                .frame(width: 12, height: 12)
                .onTapGesture {
                    NSApplication.shared.terminate(nil)
                }

            // 最小化按钮 - 黄色
            Circle()
                .fill(Color(hex: "#febc2e"))
                .frame(width: 12, height: 12)
                .onTapGesture {
                    NSApplication.shared.mainWindow?.miniaturize(nil)
                }
        }
    }
}

// MARK: - Theme Toggle Button

struct ThemeToggleButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isHovering = false

    var body: some View {
        Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isHovering ? ThemeColors.accent : ThemeColors.textSecondary)
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    themeManager.toggleTheme()
                }
            }
            .onHover { hovering in
                isHovering = hovering
            }
            .help(themeManager.isDarkMode
                ? String(localized: "theme.switchToLight", bundle: LanguageManager.shared.bundle)
                : String(localized: "theme.switchToDark", bundle: LanguageManager.shared.bundle))
    }
}

// MARK: - Settings Toggle Button

struct SettingsToggleButton: View {
    @Binding var isExpanded: Bool
    @State private var isHovering = false

    var body: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isHovering ? ThemeColors.accent : ThemeColors.textSecondary)
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
            .rotationEffect(.degrees(isExpanded ? 90 : 0))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            .onHover { hovering in
                isHovering = hovering
            }
            .help(isExpanded
                ? String(localized: "theme.collapse", bundle: LanguageManager.shared.bundle)
                : String(localized: "theme.expand", bundle: LanguageManager.shared.bundle))
    }
}

// MARK: - Language Toggle Button

struct LanguageToggleButton: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            languageManager.toggleLanguage()
        }) {
            Image(systemName: "globe")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isHovering ? ThemeColors.accent : ThemeColors.textSecondary)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .help(languageManager.isChinese
            ? languageManager.localized("language.switchToEnglish")
            : languageManager.localized("language.switchToChinese"))
    }
}
