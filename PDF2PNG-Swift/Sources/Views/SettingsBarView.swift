import SwiftUI

struct SettingsBarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
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
                    modePicker
                    Spacer()
                    if appState.settings.qualityFirst {
                        dpiControls
                    } else {
                        sizeControls
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
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
            .accessibilityLabel("Quality first mode")
            .accessibilityHint("Renders at maximum DPI, ignores file size limit")
            .accessibilityValue(appState.settings.qualityFirst ? "selected" : "not selected")

            Rectangle()
                .fill(ThemeColors.borderNormal)
                .frame(width: 1, height: 16)
                .accessibilityHidden(true)

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
            .accessibilityLabel("Size limit mode")
            .accessibilityHint("Automatically adjusts DPI to fit within the specified file size limit")
            .accessibilityValue(appState.settings.qualityFirst ? "not selected" : "selected")
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(ThemeColors.backgroundSecondary)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ThemeColors.borderNormal, lineWidth: 1))
    }

    // MARK: - DPI Controls (quality-first mode)

    private var dpiControls: some View {
        HStack(spacing: 4) {
            ThemedNSSlider(
                value: Binding(
                    get: { Double(appState.settings.maxDPI) },
                    set: { appState.settings.maxDPI = Int($0) }
                ),
                range: 150...2400,
                increment: 10
            )
            .frame(width: 80, height: 16)

            ThemedNumberField(value: $appState.settings.maxDPI, width: 42)
                .frame(width: 42, height: 22)

            Text("DPI")
                .font(.system(size: 10))
                .foregroundColor(ThemeColors.textMuted)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Size Controls (size-limit mode)

    private var sizeControls: some View {
        VStack(alignment: .trailing, spacing: 6) {
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

            Picker("Calculation Mode", selection: $appState.settings.sizeCalculationMode) {
                Text(LanguageManager.shared.localized("settings.size.safe"))
                    .tag(ConversionSettings.SizeCalculationMode.safe)
                Text(LanguageManager.shared.localized("settings.size.aggressive"))
                    .tag(ConversionSettings.SizeCalculationMode.aggressive)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 150)

            if appState.settings.sizeCalculationMode == .aggressive {
                Text(LanguageManager.shared.localized("settings.size.warning"))
                    .font(.system(size: 9))
                    .foregroundColor(ThemeColors.textMuted)
            } else {
                Text("").font(.system(size: 9))
            }
        }
    }
}
