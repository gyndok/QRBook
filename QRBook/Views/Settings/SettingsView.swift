import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("defaultSize") private var defaultSize = 512
    @AppStorage("defaultErrorCorrection") private var defaultErrorCorrection = "M"
    @AppStorage("defaultBrightnessBoost") private var defaultBrightnessBoost = true
    @AppStorage("defaultAutoFavorite") private var defaultAutoFavorite = false

    @Query private var qrCodes: [QRCode]
    @Query private var scanEvents: [ScanEvent]
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager

    @State private var showPaywall = false
    @State private var versionTapCount = 0
    @State private var showDevUnlockAlert = false
    @State private var devCode = ""

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

            // PRO Section
            Section("QR Snap Vault PRO") {
                if storeManager.isProUnlocked {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.electricViolet)
                        if storeManager.devUnlock && !storeManager.hasStoreKitEntitlement {
                            Text("PRO Unlocked (Developer)")
                        } else {
                            Text("PRO Unlocked")
                        }
                        Spacer()
                    }
                    .foregroundStyle(Color.electricViolet)
                } else {
                    HStack {
                        Image(systemName: "star.circle")
                            .foregroundStyle(.secondary)
                        Text("Free")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Upgrade to PRO") {
                            showPaywall = true
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.electricViolet)
                    }
                }

                Button {
                    Task { await storeManager.restorePurchases() }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
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
                    HStack {
                        Label("Manage Folders", systemImage: "folder")
                        if !storeManager.isProUnlocked {
                            Spacer()
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.electricViolet)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }

                NavigationLink {
                    BulkImportView()
                } label: {
                    HStack {
                        Label("Bulk Import", systemImage: "square.and.arrow.down.on.square")
                        if !storeManager.isProUnlocked {
                            Spacer()
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.electricViolet)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }

                Button {
                    exportData()
                } label: {
                    Label("Export All QR Codes", systemImage: "square.and.arrow.up")
                }
                .disabled(qrCodes.isEmpty)

                Button(role: .destructive) {
                    clearHistory()
                } label: {
                    Label("Clear Scan History", systemImage: "clock.arrow.circlepath")
                }
                .disabled(scanEvents.isEmpty)
            }

            // About
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                    #if DEBUG
                    .onTapGesture {
                        versionTapCount += 1
                        if versionTapCount >= 3 {
                            versionTapCount = 0
                            if storeManager.devUnlock {
                                storeManager.devUnlock = false
                            } else {
                                showDevUnlockAlert = true
                            }
                        }
                    }
                    #endif
                LabeledContent("iCloud Sync", value: "Enabled")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) { PaywallView() }
        #if DEBUG
        .alert("Developer Unlock", isPresented: $showDevUnlockAlert) {
            SecureField("Code", text: $devCode)
            Button("Unlock") {
                if devCode == "qrbook2026" {
                    storeManager.devUnlock = true
                }
                devCode = ""
            }
            Button("Cancel", role: .cancel) { devCode = "" }
        } message: {
            Text("Enter developer code:")
        }
        #endif
    }

    private func clearHistory() {
        for event in scanEvents {
            modelContext.delete(event)
        }
        HapticManager.success()
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
