import SwiftUI
import UniformTypeIdentifiers

// MARK: - Theme Manager

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

// MARK: - Language Manager

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            updateBundle()
        }
    }

    /// 当前语言的 Bundle
    @Published private(set) var bundle: Bundle = .module

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
        for langCode in possibleCodes {
            if let path = Bundle.module.path(forResource: langCode, ofType: "lproj"),
               let langBundle = Bundle(path: path) {
                bundle = langBundle
                print("[LanguageManager] Loaded bundle: \(langCode).lproj")
                return
            }
        }
        bundle = .module
        print("[LanguageManager] Fallback to module bundle")
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

// MARK: - Theme Colors

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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var isDragging = false
    @State private var isHoveringDropZone = false
    @State private var isSettingsExpanded = false

    // 用于触发主题刷新的计算属性
    private var themeRefreshKey: Bool { themeManager.isDarkMode }
    // 用于触发语言刷新的计算属性
    private var languageRefreshKey: String { languageManager.currentLanguage }

    var body: some View {
        Group {
            if appState.pendingFiles.isEmpty && appState.tasks.isEmpty {
                emptyStateView
            } else {
                workingStateView
            }
        }
        .id("\(themeRefreshKey)-\(languageManager.refreshID)")  // 主题或语言变化时强制刷新
        .background(ThemeColors.backgroundPrimary)
        .fileImporter(
            isPresented: $appState.showFilePicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                appState.addFiles(urls)
            case .failure(let error):
                appState.showError(error.localizedDescription)
            }
        }
        .alert(String(localized: "error.title", bundle: LanguageManager.shared.bundle), isPresented: $appState.showError) {
            Button(String(localized: "error.ok", bundle: LanguageManager.shared.bundle), role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? String(localized: "error.unknown", bundle: LanguageManager.shared.bundle))
        }
        .alert(String(localized: "overwrite.title", bundle: LanguageManager.shared.bundle), isPresented: $appState.showOverwriteConfirm) {
            Button(String(localized: "overwrite.cancel", bundle: LanguageManager.shared.bundle), role: .cancel) {
                appState.filesToOverwrite = []
            }
            Button(String(localized: "overwrite.confirm", bundle: LanguageManager.shared.bundle), role: .destructive) {
                appState.confirmOverwriteAndConvert()
            }
        } message: {
            Text(String(localized: "overwrite.message", bundle: LanguageManager.shared.bundle).replacingOccurrences(of: "%@", with: appState.filesToOverwrite.joined(separator: "\n")))
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            // 顶部区域
            VStack(spacing: 15) {
                // macOS 控制按钮
                HStack {
                    MacControlButtons()
                    Spacer()
                }

                // 标题
                Text("P D F  →  P N G")
                    .font(.system(size: 24, weight: .light))
                    .tracking(6)
                    .foregroundColor(ThemeColors.textPrimary)

                // 副标题
                Text(LanguageManager.shared.localized("app.subtitle"))
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(ThemeColors.textSecondary)
            }
            .padding(.horizontal, 15)
            .padding(.top, 12)
            .padding(.bottom, 25)

            // 黄色拖放区域
            YellowDropZone(
                isHovering: $isHoveringDropZone,
                onTap: { appState.showFilePicker = true },
                onDrop: { urls in appState.addFiles(urls) }
            )
            .frame(height: 180)

            // 底部提示 - 两行
            VStack(spacing: 4) {
                Text(LanguageManager.shared.localized("app.dropHint1"))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(ThemeColors.textPrimary)
                Text(LanguageManager.shared.localized("app.dropHint2"))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(ThemeColors.textPrimary)
            }
            .padding(.horizontal, 15)
            .padding(.top, 25)
            .padding(.bottom, 35)
        }
    }

    // MARK: - Working State View

    private var workingStateView: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar

            // 设置区域
            settingsBar

            // 文件列表
            fileListView

            // 底部按钮栏
            bottomBar
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                MacControlButtons()

                Text("PDF → PNG")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ThemeColors.textPrimary)

                Spacer()

                LanguageToggleButton()
                ThemeToggleButton()
                SettingsToggleButton(isExpanded: $isSettingsExpanded)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)

            // 分隔线
            Rectangle()
                .fill(ThemeColors.borderNormal)
                .frame(height: 0.5)
        }
    }

    // MARK: - Settings Bar

    private var settingsBar: some View {
        VStack(spacing: 0) {
            // 可折叠的设置内容
            if isSettingsExpanded {
                // 设置标题
                HStack {
                    Text(LanguageManager.shared.localized("settings.title"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ThemeColors.textMuted)
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.top, 10)
                .padding(.bottom, 6)

                HStack(spacing: 12) {
                    // 模式切换
                    HStack(spacing: 0) {
                        Button(action: { appState.settings.qualityFirst = true }) {
                            Text(LanguageManager.shared.localized("settings.qualityFirst"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(appState.settings.qualityFirst ? ThemeColors.pickerAccent : ThemeColors.textMuted)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        // 竖线分隔符
                        Rectangle()
                            .fill(ThemeColors.borderNormal)
                            .frame(width: 1, height: 16)

                        Button(action: { appState.settings.qualityFirst = false }) {
                            Text(LanguageManager.shared.localized("settings.sizeLimit"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(appState.settings.qualityFirst ? ThemeColors.textMuted : ThemeColors.pickerAccent)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .background(ThemeColors.backgroundSecondary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ThemeColors.borderNormal, lineWidth: 1)
                    )

                    Spacer()

                    if appState.settings.qualityFirst {
                        // 质量优先模式 - 显示 DPI 设置
                        ThemedNSSlider(
                            value: Binding(
                                get: { Double(appState.settings.maxDPI) },
                                set: { appState.settings.maxDPI = Int($0) }
                            ),
                            range: 150...1200
                        )
                        .frame(width: 80, height: 16)

                        HStack(spacing: 4) {
                            ThemedNumberField(value: $appState.settings.maxDPI, width: 42)
                                .frame(width: 42, height: 22)

                            Text("DPI")
                                .font(.system(size: 10))
                                .foregroundColor(ThemeColors.textMuted)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    } else {
                        // 大小限制模式 - 显示文件大小设置
                        ThemedNSSlider(
                            value: $appState.settings.maxSizeMB,
                            range: 1...50
                        )
                        .frame(width: 80, height: 16)

                        HStack(spacing: 4) {
                            ThemedDoubleField(value: $appState.settings.maxSizeMB, width: 42)
                                .frame(width: 42, height: 22)

                            Text("MB")
                                .font(.system(size: 10))
                                .foregroundColor(ThemeColors.textMuted)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// 设置摘要文本
    private var settingsSummary: String {
        if appState.settings.qualityFirst {
            return "\(appState.settings.maxDPI) DPI"
        } else {
            return "\(Int(appState.settings.maxSizeMB)) MB"
        }
    }

    /// 是否有失败的任务
    private var hasFailedTasks: Bool {
        appState.tasks.contains { task in
            if case .failed = task.status { return true }
            return false
        }
    }

    /// 是否有已完成的任务（不在转换中）
    private var hasCompletedTasks: Bool {
        !appState.isConverting && appState.tasks.contains { task in
            if case .completed = task.status { return true }
            return false
        }
    }

    /// 是否可以开始转换
    private var canStartConversion: Bool {
        !appState.pendingFiles.isEmpty || hasFailedTasks || hasCompletedTasks
    }

    /// 转换按钮标题
    private var convertButtonTitle: String {
        if !appState.pendingFiles.isEmpty {
            return String(localized: "button.startConvert", bundle: LanguageManager.shared.bundle)
        } else if hasFailedTasks || hasCompletedTasks {
            return String(localized: "button.restart", bundle: LanguageManager.shared.bundle)
        }
        return String(localized: "button.startConvert", bundle: LanguageManager.shared.bundle)
    }

    /// 重新开始失败的任务
    private func restartFailedTasks() {
        let failedURLs = appState.tasks.compactMap { task -> URL? in
            if case .failed = task.status {
                return task.sourceURL
            }
            return nil
        }
        appState.tasks.removeAll()
        appState.addFiles(failedURLs)
    }

    /// 文件列表摘要（文件数量 + 当前设置）
    private var fileListSummary: String {
        let count = appState.pendingFiles.count + appState.tasks.count
        let setting = appState.settings.qualityFirst
            ? "\(appState.settings.maxDPI) DPI"
            : "\(Int(appState.settings.maxSizeMB)) MB"
        return String(localized: "fileList.summary", defaultValue: "\(count) files · \(setting)")
            .replacingOccurrences(of: "%d", with: "\(count)")
            .replacingOccurrences(of: "%@", with: setting)
    }

    // MARK: - File List

    private var fileListView: some View {
        VStack(spacing: 0) {
            // 文件列表标题
            HStack {
                Text(LanguageManager.shared.localized("fileList.title"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ThemeColors.textMuted)
                Spacer()
                Text(fileListSummary)
                    .font(.system(size: 10))
                    .foregroundColor(ThemeColors.textMuted)
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 4) {
                    // 待转换文件
                    ForEach(appState.pendingFiles, id: \.self) { url in
                        FileItemView(
                            url: url,
                            status: nil,
                            onRemove: { appState.removeFile(url) }
                        )
                    }

                    // 转换任务
                    ForEach(appState.tasks) { task in
                        FileItemView(
                            url: task.sourceURL,
                            status: task.status,
                            onRemove: nil
                        )
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
        }
        .background(ThemeColors.backgroundPrimary)
        .onDrop(of: [UTType.pdf, UTType.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 8) {
            // 添加按钮
            Button(action: { appState.showFilePicker = true }) {
                Text(LanguageManager.shared.localized("button.add"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ThemeColors.textSecondary)
                    .frame(width: 56, height: 28)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ThemeColors.borderNormal, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(appState.isConverting)

            // 清空按钮
            Button(action: { appState.clearFiles() }) {
                Text(LanguageManager.shared.localized("button.clear"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ThemeColors.textSecondary)
                    .frame(width: 56, height: 28)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ThemeColors.borderNormal, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(appState.isConverting)

            Spacer()

            if appState.isConverting {
                // 取消按钮
                Button(action: { appState.cancelConversion() }) {
                    Text(LanguageManager.shared.localized("button.cancel"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ThemeColors.textSecondary)
                        .frame(width: 56, height: 28)
                        .background(ThemeColors.backgroundSecondary)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ThemeColors.borderNormal, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            } else {
                // 转换按钮 - 黄色
                Button(action: {
                    if !appState.pendingFiles.isEmpty {
                        appState.selectOutputAndConvert()
                    } else if hasFailedTasks {
                        // 重新开始：将失败的任务移回待转换列表
                        restartFailedTasks()
                    } else if hasCompletedTasks {
                        // 所有任务完成后：清空任务列表，准备新的转换
                        appState.tasks.removeAll()
                    }
                }) {
                    Text(convertButtonTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 72, height: 28)
                        .background(canStartConversion ? ThemeColors.accent : ThemeColors.accent.opacity(0.5))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canStartConversion)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .overlay(
            Rectangle()
                .fill(ThemeColors.borderNormal)
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Methods

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            appState.addFiles([url])
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil),
                       url.pathExtension.lowercased() == "pdf" {
                        DispatchQueue.main.async {
                            appState.addFiles([url])
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Yellow Drop Zone

struct YellowDropZone: View {
    @Binding var isHovering: Bool
    let onTap: () -> Void
    let onDrop: ([URL]) -> Void

    var body: some View {
        ZStack {
            // 黄色背景
            Rectangle()
                .fill(ThemeColors.accent)

            // Hover 时的白色遮罩
            if isHovering {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
            }

            // 图标
            Text(isHovering ? "+" : "↓")
                .font(.system(size: isHovering ? 72 : 48, weight: .light))
                .foregroundColor(.black)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onDrop(of: [UTType.pdf, UTType.fileURL], isTargeted: $isHovering) { providers in
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                onDrop([url])
                            }
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil),
                           url.pathExtension.lowercased() == "pdf" {
                            DispatchQueue.main.async {
                                onDrop([url])
                            }
                        }
                    }
                }
            }
            return true
        }
    }
}

// MARK: - macOS Control Buttons

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
            .help(themeManager.isDarkMode ? String(localized: "theme.switchToLight", bundle: LanguageManager.shared.bundle) : String(localized: "theme.switchToDark", bundle: LanguageManager.shared.bundle))
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
            .help(isExpanded ? String(localized: "theme.collapse", bundle: LanguageManager.shared.bundle) : String(localized: "theme.expand", bundle: LanguageManager.shared.bundle))
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
        .help(languageManager.isChinese ? languageManager.localized("language.switchToEnglish") : languageManager.localized("language.switchToChinese"))
    }
}

// MARK: - File Item View

struct FileItemView: View {
    let url: URL
    let status: TaskStatus?
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            // PDF 图标
            Image(systemName: "doc.fill")
                .font(.system(size: 20))
                .foregroundColor(ThemeColors.fileIcon)

            // 文件信息
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ThemeColors.textPrimary)
                    .lineLimit(1)

                if let status = status {
                    Text(status.description)
                        .font(.system(size: 10))
                        .foregroundColor(statusColor)
                } else {
                    Text(fileSizeString)
                        .font(.system(size: 10))
                        .foregroundColor(ThemeColors.textMuted)
                }
            }

            Spacer()

            // 状态指示器
            if let status = status {
                statusIndicator(for: status)
            }

            // 删除按钮
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Text("×")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ThemeColors.textMuted)
                }
                .buttonStyle(.plain)
                .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(ThemeColors.backgroundSecondary)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ThemeColors.borderNormal, lineWidth: 1)
        )
    }

    private var fileSizeString: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private var statusColor: Color {
        guard let status = status else { return ThemeColors.textSecondary }
        switch status {
        case .pending: return ThemeColors.textSecondary
        case .converting: return ThemeColors.statusTextProgress
        case .completed: return ThemeColors.statusTextSuccess
        case .failed: return ThemeColors.statusTextError
        }
    }

    @ViewBuilder
    private func statusIndicator(for status: TaskStatus) -> some View {
        switch status {
        case .converting(let progress, _, _):
            ProgressView(value: progress)
                .frame(width: 50)
                .tint(ThemeColors.accent)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(ThemeColors.success)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(ThemeColors.error)
        case .pending:
            EmptyView()
        }
    }
}

// MARK: - Native NSTextField Wrapper

struct ThemedNumberField: NSViewRepresentable {
    @Binding var value: Int
    let width: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textField.isBordered = false
        textField.drawsBackground = true
        textField.backgroundColor = NSColor(ThemeColors.backgroundInput)
        textField.textColor = NSColor(ThemeColors.textPrimary)
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 6
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        textField.focusRingType = .none
        textField.stringValue = "\(value)"
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if !context.coordinator.isEditing {
            nsView.stringValue = "\(value)"
        }
        // 更新主题相关颜色
        nsView.backgroundColor = NSColor(ThemeColors.backgroundInput)
        nsView.textColor = NSColor(ThemeColors.textPrimary)
        nsView.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ThemedNumberField
        var isEditing = false

        init(_ parent: ThemedNumberField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
            if let textField = obj.object as? NSTextField {
                textField.layer?.borderColor = NSColor(ThemeColors.accent).cgColor
                textField.layer?.borderWidth = 1.5
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            if let textField = obj.object as? NSTextField {
                textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
                textField.layer?.borderWidth = 1
                if let intValue = Int(textField.stringValue) {
                    parent.value = intValue
                }
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let intValue = Int(control.stringValue) {
                    parent.value = intValue
                }
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

// MARK: - ThemedNumberField for Double

struct ThemedDoubleField: NSViewRepresentable {
    @Binding var value: Double
    let width: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textField.isBordered = false
        textField.drawsBackground = true
        textField.backgroundColor = NSColor(ThemeColors.backgroundInput)
        textField.textColor = NSColor(ThemeColors.textPrimary)
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 6
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        textField.focusRingType = .none
        textField.stringValue = "\(Int(value))"
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if !context.coordinator.isEditing {
            nsView.stringValue = "\(Int(value))"
        }
        // 更新主题相关颜色
        nsView.backgroundColor = NSColor(ThemeColors.backgroundInput)
        nsView.textColor = NSColor(ThemeColors.textPrimary)
        nsView.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ThemedDoubleField
        var isEditing = false

        init(_ parent: ThemedDoubleField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
            if let textField = obj.object as? NSTextField {
                textField.layer?.borderColor = NSColor(ThemeColors.accent).cgColor
                textField.layer?.borderWidth = 1.5
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            if let textField = obj.object as? NSTextField {
                textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
                textField.layer?.borderWidth = 1
                if let doubleValue = Double(textField.stringValue) {
                    parent.value = doubleValue
                }
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let doubleValue = Double(control.stringValue) {
                    parent.value = doubleValue
                }
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

// MARK: - Themed NS Slider (Consistent Style)

struct ThemedNSSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    @ObservedObject private var themeManager = ThemeManager.shared

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider()
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = value
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.valueChanged(_:))
        slider.controlSize = .small
        slider.sliderType = .linear
        slider.isContinuous = true
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false

        // 设置外观以适应深色/浅色模式
        updateSliderAppearance(slider)
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        nsView.doubleValue = value
        updateSliderAppearance(nsView)
    }

    private func updateSliderAppearance(_ slider: NSSlider) {
        // 根据主题设置外观
        if themeManager.isDarkMode {
            slider.appearance = NSAppearance(named: .darkAqua)
        } else {
            slider.appearance = NSAppearance(named: .aqua)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ThemedNSSlider

        init(_ parent: ThemedNSSlider) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: NSSlider) {
            parent.value = sender.doubleValue
        }
    }
}

// MARK: - Themed Slider (SwiftUI - kept for compatibility)

struct ThemedSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        Slider(value: $value, in: range, step: step)
            .tint(ThemeColors.accent)
            .controlSize(.small)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(isEnabled ? ThemeColors.accent : ThemeColors.accent.opacity(0.5))
            .foregroundColor(.black)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.clear)
            .foregroundColor(isEnabled ? ThemeColors.textSecondary : ThemeColors.textMuted)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ThemeColors.borderNormal, lineWidth: 1)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
        .frame(width: 526, height: 450)
}
