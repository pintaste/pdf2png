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

    private var themeRefreshKey: Bool { themeManager.isDarkMode }
    private var languageRefreshKey: String { languageManager.currentLanguage }

    var body: some View {
        Group {
            if appState.pendingFiles.isEmpty && appState.tasks.isEmpty {
                emptyStateView
            } else {
                workingStateView
            }
        }
        .id("\(themeRefreshKey)-\(languageManager.refreshID)")
        .background(ThemeColors.backgroundPrimary)
        .fileImporter(
            isPresented: $appState.showFilePicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls): appState.addFiles(urls)
            case .failure(let error): appState.showError(error.localizedDescription)
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
            Text(String(localized: "overwrite.message", bundle: LanguageManager.shared.bundle)
                .replacingOccurrences(of: "%@", with: appState.filesToOverwrite.joined(separator: "\n")))
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                HStack {
                    MacControlButtons()
                    Spacer()
                }

                Text("P D F  →  P N G")
                    .font(.system(size: 24, weight: .light))
                    .tracking(6)
                    .foregroundColor(ThemeColors.textPrimary)

                Text(LanguageManager.shared.localized("app.subtitle"))
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(ThemeColors.textSecondary)
            }
            .padding(.horizontal, 15)
            .padding(.top, 12)
            .padding(.bottom, 25)

            YellowDropZone(
                isHovering: $isHoveringDropZone,
                onTap: { appState.showFilePicker = true },
                onDrop: { urls in appState.addFiles(urls) }
            )
            .frame(height: 180)

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
            titleBar
            SettingsBarView(isExpanded: $isSettingsExpanded)
                .environmentObject(appState)
            fileListView
            BottomBarView()
                .environmentObject(appState)
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

            Rectangle()
                .fill(ThemeColors.borderNormal)
                .frame(height: 0.5)
        }
    }

    // MARK: - File List

    private var fileListSummary: String {
        let count = appState.pendingFiles.count + appState.tasks.count
        let setting = appState.settings.qualityFirst
            ? "\(appState.settings.maxDPI) DPI"
            : "\(Int(appState.settings.maxSizeMB)) MB"
        return String(localized: "fileList.summary", defaultValue: "\(count) files · \(setting)")
            .replacingOccurrences(of: "%d", with: "\(count)")
            .replacingOccurrences(of: "%@", with: setting)
    }

    private var fileListView: some View {
        VStack(spacing: 0) {
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
                    ForEach(appState.pendingFiles, id: \.self) { url in
                        FileItemView(url: url, status: nil, onRemove: { appState.removeFile(url) })
                    }
                    ForEach(appState.tasks) { task in
                        FileItemView(url: task.sourceURL, status: task.status, onRemove: nil)
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

    // MARK: - Drop Handling

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        DispatchQueue.main.async { appState.addFiles([url]) }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil),
                       url.pathExtension.lowercased() == "pdf" {
                        DispatchQueue.main.async { appState.addFiles([url]) }
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
        .frame(width: 526, height: 450)
}
