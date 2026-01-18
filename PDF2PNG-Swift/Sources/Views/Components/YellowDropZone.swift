import SwiftUI
import UniformTypeIdentifiers

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
