import SwiftUI

/// 设置视图
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var outputPath: String = ""
    @State private var useCustomOutput: Bool = false

    var body: some View {
        Form {
            // 输出设置
            Section("输出设置") {
                Toggle("使用自定义输出目录", isOn: $useCustomOutput)

                if useCustomOutput {
                    HStack {
                        TextField("输出目录", text: $outputPath)
                            .textFieldStyle(.roundedBorder)

                        Button("选择...") {
                            selectOutputDirectory()
                        }
                    }
                } else {
                    Text("输出到源文件所在目录")
                        .foregroundColor(.secondary)
                }
            }

            // 质量设置
            Section("质量设置") {
                Picker("输出模式", selection: $appState.settings.qualityFirst) {
                    Text("大小限制").tag(false)
                    Text("质量优先").tag(true)
                }
                .pickerStyle(.segmented)

                if !appState.settings.qualityFirst {
                    HStack {
                        Text("最大文件大小")
                        Spacer()
                        TextField("", value: $appState.settings.maxSizeMB, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Text("MB")
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("最大 DPI")
                        Spacer()
                        Text("\(appState.settings.maxDPI)")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(appState.settings.maxDPI) },
                            set: { appState.settings.maxDPI = Int($0) }
                        ),
                        in: 150...2400,
                        step: 50
                    )
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("最小 DPI")
                        Spacer()
                        Text("\(appState.settings.minDPI)")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(appState.settings.minDPI) },
                            set: { appState.settings.minDPI = Int($0) }
                        ),
                        in: 72...600,
                        step: 50
                    )
                }
            }

            // 预设
            Section("快速预设") {
                HStack {
                    presetButton(title: "标准", dpi: 600, sizeMB: 5.0, qualityFirst: false)
                    presetButton(title: "高清", dpi: 1200, sizeMB: 10.0, qualityFirst: false)
                    presetButton(title: "极致", dpi: 2400, sizeMB: 0, qualityFirst: true)
                }
            }

            // 关于
            Section("关于") {
                HStack {
                    Text("PDF2PNG Swift 原生版")
                    Spacer()
                    Text("v1.0.0")
                        .foregroundColor(.secondary)
                }

                Link("GitHub 仓库",
                     destination: URL(string: "https://github.com/your-repo/pdf2png")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 500)
        .onAppear {
            if let dir = appState.settings.outputDirectory {
                outputPath = dir.path
                useCustomOutput = true
            }
        }
        .onChange(of: useCustomOutput) { newValue in
            if !newValue {
                appState.settings.outputDirectory = nil
            }
        }
    }

    // MARK: - Methods

    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            outputPath = url.path
            appState.settings.outputDirectory = url
        }
    }

    private func presetButton(title: String, dpi: Int, sizeMB: Double, qualityFirst: Bool) -> some View {
        Button(action: {
            appState.settings.maxDPI = dpi
            appState.settings.maxSizeMB = sizeMB
            appState.settings.qualityFirst = qualityFirst
        }) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
