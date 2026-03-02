import SwiftUI

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
        case .cancelled: return ThemeColors.textMuted // Use a muted color for cancelled
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
        case .cancelled:
            Image(systemName: "xmark.circle.fill") // A cross mark to indicate cancellation
                .foregroundColor(ThemeColors.textMuted) // Muted color
        case .pending:
            EmptyView()
        }
    }
}
