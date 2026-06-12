import SwiftUI

struct BottomBarView: View {
    @EnvironmentObject var appState: AppState

    private var hasFailedTasks: Bool {
        appState.tasks.contains { task in
            if case .failed = task.status { return true }
            return false
        }
    }

    private var hasCompletedTasks: Bool {
        guard !appState.isConverting else { return false }
        return appState.tasks.contains { task in
            if case .completed = task.status { return true }
            return false
        }
    }

    private var canStartConversion: Bool {
        !appState.pendingFiles.isEmpty || hasFailedTasks || hasCompletedTasks
    }

    private var convertButtonTitle: String {
        if !appState.pendingFiles.isEmpty {
            return String(localized: "button.startConvert", bundle: LanguageManager.shared.bundle)
        } else if hasFailedTasks || hasCompletedTasks {
            return String(localized: "button.restart", bundle: LanguageManager.shared.bundle)
        }
        return String(localized: "button.startConvert", bundle: LanguageManager.shared.bundle)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 转换完成摘要栏
            if !appState.isConverting && !appState.tasks.isEmpty {
                completionSummary
            }

            // 操作按钮栏
            HStack(spacing: 8) {
                Button(action: { appState.showFilePicker = true }) {
                    Text(LanguageManager.shared.localized("button.add"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ThemeColors.textSecondary)
                        .frame(width: 56, height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ThemeColors.borderNormal, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(appState.isConverting)
                .accessibilityLabel("Add PDF files")
                .accessibilityHint("Opens the file picker to select PDF files")

                Button(action: { appState.clearFiles() }) {
                    Text(LanguageManager.shared.localized("button.clear"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ThemeColors.textSecondary)
                        .frame(width: 56, height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ThemeColors.borderNormal, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(appState.isConverting)
                .accessibilityLabel("Clear file list")
                .accessibilityHint("Removes all files from the list")

                Spacer()

                if appState.isConverting {
                    Button(action: { appState.cancelConversion() }) {
                        Text(LanguageManager.shared.localized("button.cancel"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ThemeColors.textSecondary)
                            .frame(width: 56, height: 28)
                            .background(ThemeColors.backgroundSecondary)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(ThemeColors.borderNormal, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cancel conversion")
                    .accessibilityHint("Stops the current conversion in progress")
                } else {
                    Button(action: {
                        if !appState.pendingFiles.isEmpty {
                            appState.selectOutputAndConvert()
                        } else if hasFailedTasks || hasCompletedTasks {
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
                    .accessibilityLabel(convertButtonTitle)
                    .accessibilityHint(appState.pendingFiles.isEmpty
                        ? "Restarts previously converted files"
                        : "Selects output folder and starts converting PDF files to PNG")
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .overlay(Rectangle().fill(ThemeColors.borderNormal).frame(height: 1), alignment: .top)
    }

    // MARK: - Completion Summary

    @ViewBuilder
    private var completionSummary: some View {
        let completed = appState.completedTaskCount
        let failed = appState.failedTaskCount
        if completed > 0 || failed > 0 {
            HStack(spacing: 6) {
                if completed > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ThemeColors.success)
                        .font(.system(size: 11))
                    Text("\(completed) \(completed == 1 ? "file" : "files") saved")
                        .font(.system(size: 11))
                        .foregroundColor(ThemeColors.textSecondary)
                }
                if failed > 0 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(ThemeColors.error)
                        .font(.system(size: 11))
                    Text("\(failed) failed")
                        .font(.system(size: 11))
                        .foregroundColor(ThemeColors.statusTextError)
                }
                Spacer()
                Button(action: { appState.showOutputInFinder() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                        Text("Show in Finder")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(ThemeColors.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show output in Finder")
                .accessibilityHint("Opens the output folder in Finder")
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 6)
            .background(ThemeColors.backgroundSecondary)
            .overlay(Rectangle().fill(ThemeColors.borderNormal).frame(height: 0.5), alignment: .top)
        }
    }
}
