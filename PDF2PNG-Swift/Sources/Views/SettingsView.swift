import SwiftUI

/// 设置视图
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var outputPath: String = ""
    @State private var useCustomOutput: Bool = false

    var body: some View {
        Form {
            // 输出设置
            Section(String(localized: "settingsView.outputSettings", bundle: .module)) {
                Toggle(String(localized: "settingsView.useCustomOutput", bundle: .module), isOn: $useCustomOutput)

                if useCustomOutput {
                    HStack {
                        TextField(String(localized: "settingsView.outputDirectory", bundle: .module), text: $outputPath)
                            .textFieldStyle(.roundedBorder)

                        Button(String(localized: "settingsView.selectDirectory", bundle: .module)) {
                            selectOutputDirectory()
                        }
                    }
                } else {
                    Text("settingsView.outputToSource", bundle: .module)
                        .foregroundColor(.secondary)
                }
            }

            // 质量设置
            Section(String(localized: "settingsView.qualitySettings", bundle: .module)) {
                Picker(String(localized: "settingsView.outputMode", bundle: .module), selection: $appState.settings.qualityFirst) {
                    Text("settings.sizeLimit", bundle: .module).tag(false)
                    Text("settings.qualityFirst", bundle: .module).tag(true)
                }
                .pickerStyle(.segmented)

                if !appState.settings.qualityFirst {
                    HStack {
                        Text("settingsView.maxFileSize", bundle: .module)
                        Spacer()
                        TextField("", value: $appState.settings.maxSizeMB, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Text("MB")
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("settingsView.maxDPI", bundle: .module)
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
                        Text("settingsView.minDPI", bundle: .module)
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
            Section(String(localized: "settingsView.presets", bundle: .module)) {
                HStack {
                    presetButton(title: String(localized: "settingsView.standard", bundle: .module), dpi: 600, sizeMB: 5.0, qualityFirst: false)
                    presetButton(title: String(localized: "settingsView.hd", bundle: .module), dpi: 1200, sizeMB: 10.0, qualityFirst: false)
                    presetButton(title: String(localized: "settingsView.ultra", bundle: .module), dpi: 2400, sizeMB: 0, qualityFirst: true)
                }
            }

            // 关于
            Section(String(localized: "settingsView.about", bundle: .module)) {
                HStack {
                    Text("settingsView.nativeVersion", bundle: .module)
                    Spacer()
                    Text("v4.2.0")
                        .foregroundColor(.secondary)
                }

                Link(String(localized: "settingsView.githubRepo", bundle: .module),
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
