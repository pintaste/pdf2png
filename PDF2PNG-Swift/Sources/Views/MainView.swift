import SwiftUI
import UniformTypeIdentifiers

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

    // ✅ 临时输入状态（避免 didSet 干扰）
    @State private var sizeInputText: String = ""

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
                            range: 150...2400,  // ✅ 修复：与 SettingsView 保持一致，支持到 2400
                            increment: 10  // 每次移动 10 DPI
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
                        VStack(alignment: .trailing, spacing: 6) {
                            // 大小限制模式 - 文件大小输入框
                            HStack(spacing: 4) {
                                Text(LanguageManager.shared.localized("settings.maxSize"))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ThemeColors.textSecondary)

                                ThemedDoubleField(value: $appState.settings.maxSizeMB, width: 60)
                                    .frame(width: 60, height: 24)

                                Text("MB")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ThemeColors.textMuted)
                            }
                            
                            // 新增：模式选择
                            Picker("Calculation Mode", selection: $appState.settings.sizeCalculationMode) {
                                Text(LanguageManager.shared.localized("settings.size.safe")).tag(ConversionSettings.SizeCalculationMode.safe)
                                Text(LanguageManager.shared.localized("settings.size.aggressive")).tag(ConversionSettings.SizeCalculationMode.aggressive)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(width: 150)

                            // 新增：警告信息
                            if appState.settings.sizeCalculationMode == .aggressive {
                                Text(LanguageManager.shared.localized("settings.size.warning"))
                                    .font(.system(size: 9))
                                    .foregroundColor(ThemeColors.textMuted)
                            } else {
                                // Add an empty text to maintain layout consistency
                                Text("").font(.system(size: 9))
                            }
                        }
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
                        // 直接开始转换
                        appState.selectOutputAndConvert()
                    } else if hasFailedTasks || hasCompletedTasks {
                        // 重新开始所有任务
                        appState.restartConversion()
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

// MARK: - Native NSTextField Wrapper

struct ThemedNumberField: NSViewRepresentable {
    @Binding var value: Int
    let width: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)

        // ✅ 基本输入设置
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        textField.allowsEditingTextAttributes = false
        textField.importsGraphics = false

        // 边框和背景
        textField.isBordered = false
        textField.drawsBackground = true
        textField.backgroundColor = NSColor(ThemeColors.backgroundInput)
        textField.textColor = NSColor(ThemeColors.textPrimary)
        textField.focusRingType = .none

        // Layer 设置（确保不阻挡交互）
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 6
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        textField.layer?.masksToBounds = true

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



// MARK: - MaxSizeInputField (专用大小输入框)

struct MaxSizeInputField: NSViewRepresentable {
    @Binding var value: Double
    @ObservedObject private var themeManager = ThemeManager.shared

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()

        // 基本配置
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textField.delegate = context.coordinator

        // 确保可以获得焦点和编辑
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = false
        textField.drawsBackground = true
        textField.focusRingType = .none

        // 移除可能阻止输入的样式
        textField.bezelStyle = .squareBezel
        textField.isBezeled = false

        // 主题颜色
        updateAppearance(textField)

        // 边框样式
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 6
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor

        // 初始值
        textField.stringValue = formatValue(value)

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // 确保可编辑状态始终保持
        nsView.isEditable = true
        nsView.isSelectable = true

        // 仅在非编辑状态下更新显示
        if !context.coordinator.isEditing {
            nsView.stringValue = formatValue(value)
        }

        // 更新主题（仅在非编辑时，避免干扰输入）
        if !context.coordinator.isEditing {
            updateAppearance(nsView)
        }

        if !context.coordinator.isEditing {
            nsView.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        }
    }

    private func updateAppearance(_ textField: NSTextField) {
        // 根据主题设置外观
        if themeManager.isDarkMode {
            textField.appearance = NSAppearance(named: .darkAqua)
        } else {
            textField.appearance = NSAppearance(named: .aqua)
        }
        textField.backgroundColor = NSColor(ThemeColors.backgroundInput)
        textField.textColor = NSColor(ThemeColors.textPrimary)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func formatValue(_ value: Double) -> String {
        let formatted = String(format: "%.2f", value)
        return formatted.replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: MaxSizeInputField
        var isEditing = false

        init(_ parent: MaxSizeInputField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
            if let textField = obj.object as? NSTextField {
                // 聚焦时显示蓝色边框
                textField.layer?.borderColor = NSColor(ThemeColors.accent).cgColor
                textField.layer?.borderWidth = 1.5
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            if let textField = obj.object as? NSTextField {
                // 失焦时恢复普通边框
                textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
                textField.layer?.borderWidth = 1

                // 更新值
                if let newValue = Double(textField.stringValue) {
                    parent.value = newValue
                } else {
                    // 无效输入，恢复原值
                    textField.stringValue = parent.formatValue(parent.value)
                }
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // 按 Enter 键提交
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let textField = control as? NSTextField,
                   let newValue = Double(textField.stringValue) {
                    parent.value = newValue
                }
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

// MARK: - ThemedDoubleField (全新实现)

struct ThemedDoubleField: NSViewRepresentable {
    @Binding var value: Double
    let width: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()

        // 基本配置
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textField.delegate = context.coordinator

        // 使用标准的可编辑文本框样式
        textField.isBordered = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.drawsBackground = true
        textField.focusRingType = .none

        // 主题颜色
        textField.backgroundColor = NSColor(ThemeColors.backgroundInput)
        textField.textColor = NSColor(ThemeColors.textPrimary)

        // 边框样式
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 6
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor

        // 初始值
        textField.stringValue = formatValue(value)

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // 仅在非编辑状态下更新显示
        if !context.coordinator.isEditing {
            nsView.stringValue = formatValue(value)
        }

        // 更新主题颜色
        nsView.backgroundColor = NSColor(ThemeColors.backgroundInput)
        nsView.textColor = NSColor(ThemeColors.textPrimary)
        if !context.coordinator.isEditing {
            nsView.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func formatValue(_ value: Double) -> String {
        // 格式化显示：移除末尾的 .00
        let formatted = String(format: "%.2f", value)
        return formatted.replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
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
                // 聚焦时显示蓝色边框
                textField.layer?.borderColor = NSColor(ThemeColors.accent).cgColor
                textField.layer?.borderWidth = 1.5
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            if let textField = obj.object as? NSTextField {
                // 失焦时恢复普通边框
                textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
                textField.layer?.borderWidth = 1

                // 更新值
                if let newValue = Double(textField.stringValue) {
                    parent.value = newValue
                } else {
                    // 无效输入，恢复原值
                    textField.stringValue = parent.formatValue(parent.value)
                }
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // 按 Enter 键提交
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let textField = control as? NSTextField,
                   let newValue = Double(textField.stringValue) {
                    parent.value = newValue
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
    var increment: Double = 1.0  // 步进值，默认为 1
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

        // ✅ 连续模式，允许平滑滑动
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false

        // 设置外观以适应深色/浅色模式
        updateSliderAppearance(slider)
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        // 仅在值明显不同时更新，避免循环更新
        if abs(nsView.doubleValue - value) > 0.5 {
            nsView.doubleValue = value
        }
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
            // 根据步进值对齐滑块值
            let rawValue = sender.doubleValue
            let steppedValue = round(rawValue / parent.increment) * parent.increment

            // 确保在范围内
            let clampedValue = max(parent.range.lowerBound, min(parent.range.upperBound, steppedValue))

            // 更新绑定值
            parent.value = clampedValue
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
        .frame(width: 526, height: 450)
}
