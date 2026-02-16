import SwiftUI
import SwiftData

@main
struct QRBookApp: App {
    @State private var showSplash = true
    @State private var router = DeepLinkRouter()
    @AppStorage("appearanceMode") private var appearanceMode = "dark"

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environment(router)
                    .preferredColorScheme(colorScheme)
                    .tint(Color.electricViolet)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                checkPendingShareImports()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(for: [QRCode.self, Folder.self, ScanEvent.self])
    }

    private func checkPendingShareImports() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else { return }

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) else { return }

        for file in files where file.lastPathComponent.hasPrefix("shared-import-") {
            if let data = try? Data(contentsOf: file),
               let payload = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let qrData = payload["data"],
               let typeStr = payload["type"] {
                UserDefaults.standard.set(qrData, forKey: "pendingShareData")
                UserDefaults.standard.set(typeStr, forKey: "pendingShareType")
                try? fm.removeItem(at: file)
            }
        }
    }
}
