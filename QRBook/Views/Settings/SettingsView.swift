import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("defaultSize") private var defaultSize = 512
    @AppStorage("defaultErrorCorrection") private var defaultErrorCorrection = "M"
    @AppStorage("defaultBrightnessBoost") private var defaultBrightnessBoost = true
    @AppStorage("defaultAutoFavorite") private var defaultAutoFavorite = false

    @Query private var qrCodes: [QRCode]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            // Stats
            Section("Account") {
                LabeledContent("Total QR Codes") {
                    Text("\(qrCodes.count)")
                        .foregroundStyle(Color.electricViolet)
                }
                LabeledContent("Favorites") {
                    Text("\(qrCodes.filter(\.isFavorite).count)")
                        .foregroundStyle(Color.electricViolet)
                }
            }

            // Defaults
            Section("Default Settings") {
                Picker("QR Size", selection: $defaultSize) {
                    Text("256px - Small").tag(256)
                    Text("512px - Medium").tag(512)
                    Text("1024px - Large").tag(1024)
                }

                Picker("Error Correction", selection: $defaultErrorCorrection) {
                    Text("Low (~7%)").tag("L")
                    Text("Medium (~15%)").tag("M")
                    Text("Quartile (~25%)").tag("Q")
                    Text("High (~30%)").tag("H")
                }

                Toggle("Brightness Boost by Default", isOn: $defaultBrightnessBoost)
                    .tint(Color.electricViolet)
                Toggle("Auto-Favorite New QR Codes", isOn: $defaultAutoFavorite)
                    .tint(Color.electricViolet)
            }

            Section("Appearance") {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Accent Color & Theme", systemImage: "paintpalette")
                }
            }

            // Data
            Section("Data") {
                NavigationLink {
                    ManageFoldersView()
                } label: {
                    Label("Manage Folders", systemImage: "folder")
                }

                NavigationLink {
                    BulkImportView()
                } label: {
                    Label("Bulk Import", systemImage: "square.and.arrow.down.on.square")
                }

                Button {
                    exportData()
                } label: {
                    Label("Export All QR Codes", systemImage: "square.and.arrow.up")
                }
                .disabled(qrCodes.isEmpty)
            }

            // About
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("iCloud Sync", value: "Enabled")
            }
        }
        .navigationTitle("Settings")
    }

    private func exportData() {
        let exportItems: [[String: Any]] = qrCodes.map { qr in
            [
                "id": qr.id.uuidString,
                "title": qr.title,
                "data": qr.data,
                "type": qr.typeRaw,
                "tags": qr.tags,
                "isFavorite": qr.isFavorite,
                "scanCount": qr.scanCount,
                "createdAt": ISO8601DateFormatter().string(from: qr.createdAt)
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportItems, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("qrbook-export.json")
        try? jsonString.write(to: tempURL, atomically: true, encoding: .utf8)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
