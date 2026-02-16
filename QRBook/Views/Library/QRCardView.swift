import SwiftUI
import SwiftData

struct QRCardView: View {
    @Bindable var qrCode: QRCode
    let onTap: () -> Void
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: qrCode.type.icon)
                        .font(.caption)
                        .foregroundStyle(Color.electricViolet)

                    Text(qrCode.title)
                        .font(.cardTitle)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            qrCode.isFavorite.toggle()
                            HapticManager.impact(.light)
                            qrCode.updatedAt = .now
                            DataSyncManager.syncFavorites(context: modelContext)
                        }
                    } label: {
                        Image(systemName: qrCode.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(qrCode.isFavorite ? Color.favoriteAmber : Color.secondary)
                            .font(.subheadline)
                            .symbolEffect(.bounce, value: qrCode.isFavorite)
                    }
                    .buttonStyle(.plain)
                }

                // QR preview
                if let uiImage = QRGenerator.generateQRCode(
                    from: qrCode.data,
                    correctionLevel: qrCode.errorCorrection,
                    size: 120,
                    foregroundHex: qrCode.foregroundHex,
                    backgroundHex: qrCode.backgroundHex,
                    logoImageData: qrCode.logoImageData
                ) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                    .background(Color.electricViolet.opacity(0.10))
                                    .clipShape(Capsule())
                            }
                            if qrCode.tags.count > 3 {
                                Text("+\(qrCode.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.electricViolet.opacity(0.07))
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
                        .background(Color.electricViolet.opacity(0.10))
                        .clipShape(Capsule())

                    if qrCode.scanCount > 0 {
                        Text("\(qrCode.scanCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.activeGreen)
                            .clipShape(Capsule())
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
            .themedCard()
            .contentShape(Rectangle())
        }
        .pressStyle()
        .contextMenu {
            Button { onTap() } label: { Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right") }
            Button { showEditSheet = true } label: { Label("Edit", systemImage: "pencil") }
            Button {
                let copy = QRCode(
                    title: qrCode.title + " (Copy)",
                    data: qrCode.data,
                    type: qrCode.type,
                    tags: qrCode.tags,
                    isFavorite: qrCode.isFavorite,
                    errorCorrection: qrCode.errorCorrection,
                    sizePx: qrCode.sizePx,
                    brightnessBoostDefault: qrCode.brightnessBoostDefault,
                    folderName: qrCode.folderName,
                    foregroundHex: qrCode.foregroundHex,
                    backgroundHex: qrCode.backgroundHex,
                    logoImageData: qrCode.logoImageData
                )
                modelContext.insert(copy)
                DataSyncManager.syncFavorites(context: modelContext)
                HapticManager.success()
            } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
            Button { UIPasteboard.general.string = qrCode.data } label: { Label("Copy Data", systemImage: "doc.on.doc") }
            ShareLink(item: qrCode.data) { Label("Share", systemImage: "square.and.arrow.up") }
            if !folders.isEmpty {
                Menu {
                    Button("None") {
                        qrCode.folderName = ""
                        qrCode.updatedAt = .now
                    }
                    ForEach(folders) { folder in
                        Button(folder.name) {
                            qrCode.folderName = folder.name
                            qrCode.updatedAt = .now
                        }
                    }
                } label: {
                    Label("Move to Folder", systemImage: "folder")
                }
            }
            Divider()
            Button(role: .destructive) {
                SpotlightIndexer.removeQRCode(id: qrCode.id)
                modelContext.delete(qrCode)
                DataSyncManager.syncFavorites(context: modelContext)
            } label: { Label("Delete", systemImage: "trash") }
        }
        .sheet(isPresented: $showEditSheet) {
            EditQRView(qrCode: qrCode)
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
