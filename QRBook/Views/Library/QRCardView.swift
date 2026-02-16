import SwiftUI

struct QRCardView: View {
    @Bindable var qrCode: QRCode
    let onTap: () -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: qrCode.type.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(qrCode.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        qrCode.isFavorite.toggle()
                        qrCode.updatedAt = .now
                    }
                } label: {
                    Image(systemName: qrCode.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(qrCode.isFavorite ? .red : .secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }

            // QR preview
            if let uiImage = QRGenerator.generateQRCode(
                from: qrCode.data,
                correctionLevel: qrCode.errorCorrection,
                size: 120
            ) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture(perform: onTap)
            }

            // Tags
            if !qrCode.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(qrCode.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        if qrCode.tags.count > 3 {
                            Text("+\(qrCode.tags.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Footer
            HStack {
                Text(qrCode.type.label)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.1))
                    .clipShape(Capsule())

                if qrCode.scanCount > 0 {
                    Text("\(qrCode.scanCount) scan\(qrCode.scanCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let lastUsed = qrCode.lastUsed {
                    Text(lastUsed.relativeFormatted)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .contextMenu {
            Button { onTap() } label: { Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right") }
            Button { UIPasteboard.general.string = qrCode.data } label: { Label("Copy Data", systemImage: "doc.on.doc") }
            ShareLink(item: qrCode.data) { Label("Share", systemImage: "square.and.arrow.up") }
            Divider()
            Button(role: .destructive) {
                modelContext.delete(qrCode)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
