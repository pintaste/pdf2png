import SwiftUI

/// PDF2PNG 应用入口
@main
struct PDF2PNGApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 286, height: 480)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .newItem) {
                Button(String(localized: "menu.openPDF", bundle: .module)) {
                    appState.showFilePicker = true
                }
                .keyboardShortcut("o", modifiers: .command)

                Button(String(localized: "menu.clearList", bundle: .module)) {
                    if !appState.isConverting {
                        appState.clearFiles()
                        appState.tasks.removeAll()
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(appState.isConverting)

                Divider()

                Button(String(localized: "menu.startConvert", bundle: .module)) {
                    if !appState.pendingFiles.isEmpty && !appState.isConverting {
                        appState.selectOutputAndConvert()
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState.pendingFiles.isEmpty || appState.isConverting)

                Button(String(localized: "menu.cancelConvert", bundle: .module)) {
                    if appState.isConverting {
                        appState.cancelConversion()
                    }
                }
                .keyboardShortcut(.escape, modifiers: [])
                .disabled(!appState.isConverting)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

/// 应用代理
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 配置应用
        NSApp.appearance = NSAppearance(named: .aqua)

        // 配置窗口样式 - 无边框 + 圆角
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                window.styleMask = [.borderless, .miniaturizable, .closable]
                window.isMovableByWindowBackground = true
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = true  // 使用系统阴影

                // 设置内容视图圆角遮罩
                if let contentView = window.contentView {
                    contentView.wantsLayer = true
                    contentView.layer?.backgroundColor = .clear
                    contentView.layer?.cornerRadius = 12
                    contentView.layer?.masksToBounds = true
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // 处理从 Finder 打开的文件
        NotificationCenter.default.post(
            name: .openFiles,
            object: nil,
            userInfo: ["urls": urls]
        )
    }
}

extension Notification.Name {
    static let openFiles = Notification.Name("openFiles")
}
