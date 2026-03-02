import SwiftUI

/// 语言管理器 - 运行时语言切换
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            // synchronize() 已过时，系统会自动同步
            updateBundle()
        }
    }

    /// 当前语言的 Bundle
    @Published private(set) var bundle: Bundle = .main

    /// 刷新标识符 - 用于强制刷新视图
    @Published var refreshID = UUID()

    /// 支持的语言
    static let supportedLanguages = ["en", "zh-Hans"]

    /// 是否为中文
    var isChinese: Bool {
        currentLanguage.hasPrefix("zh")
    }

    init() {
        // 从 UserDefaults 读取用户设置的语言，否则使用系统语言
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let first = languages.first {
            currentLanguage = first
        } else {
            currentLanguage = Locale.preferredLanguages.first ?? "en"
        }
        updateBundle()
    }

    /// 切换语言
    func toggleLanguage() {
        let oldLang = currentLanguage
        if isChinese {
            currentLanguage = "en"
        } else {
            currentLanguage = "zh-Hans"
        }
        print("[LanguageManager] Language changed: \(oldLang) -> \(currentLanguage)")
        // 触发刷新
        refreshID = UUID()
        print("[LanguageManager] RefreshID updated: \(refreshID)")
    }

    /// 更新 Bundle
    private func updateBundle() {
        // SPM 编译后目录名可能是小写，尝试多种格式
        let possibleCodes = isChinese ? ["zh-Hans", "zh-hans", "zh"] : ["en"]

        // 1. 优先尝试从 Bundle.main 加载（打包后的应用）
        for langCode in possibleCodes {
            // 尝试直接从 main bundle 加载
            if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
               let langBundle = Bundle(path: path) {
                bundle = langBundle
                print("[LanguageManager] Loaded from main bundle: \(langCode).lproj")
                return
            }

            // 尝试从 main bundle 中的 SPM resource bundle 加载
            if let bundlePath = Bundle.main.path(forResource: "PDF2PNG_PDF2PNG", ofType: "bundle"),
               let resourceBundle = Bundle(path: bundlePath),
               let path = resourceBundle.path(forResource: langCode, ofType: "lproj"),
               let langBundle = Bundle(path: path) {
                bundle = langBundle
                print("[LanguageManager] Loaded from resource bundle: \(langCode).lproj")
                return
            }
        }

        // 2. 最终回退到 main bundle
        bundle = .main
        print("[LanguageManager] Fallback to main bundle")
    }

    /// 语言显示名称
    var languageDisplayName: String {
        isChinese ? "中" : "EN"
    }

    /// 获取本地化字符串
    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
