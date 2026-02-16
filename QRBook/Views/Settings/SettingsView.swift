import SwiftUI
import SwiftData

// Stub — will be replaced in Task 13
struct SettingsView: View {
    @Query private var qrCodes: [QRCode]

    var body: some View {
        List {
            Section("Account") {
                LabeledContent("Total QR Codes", value: "\(qrCodes.count)")
                LabeledContent("Favorites", value: "\(qrCodes.filter(\.isFavorite).count)")
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("iCloud Sync", value: "Enabled")
            }
        }
        .navigationTitle("Settings")
    }
}
