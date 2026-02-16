import SwiftUI
import SwiftData
import UIKit
import CoreSpotlight

@main
struct QRBookApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                setupQuickActions()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
            .onChange(of: appDelegate.shortcutAction) { _, action in
                if let action {
                    router.handleQuickAction(action)
                    appDelegate.shortcutAction = nil
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                   let uuid = UUID(uuidString: id) {
                    router.showQRCode(id: uuid)
                }
            }
        }
        .modelContainer(for: [QRCode.self, Folder.self, ScanEvent.self])
    }

    private func setupQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "CreateQR",
                localizedTitle: "Create QR",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill")
            ),
            UIApplicationShortcutItem(
                type: "ScanQR",
                localizedTitle: "Scan QR",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "camera.viewfinder")
            ),
            UIApplicationShortcutItem(
                type: "Favorites",
                localizedTitle: "Favorites",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "star.fill")
            ),
        ]
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
                router.handlePendingShare(data: qrData, type: typeStr)
                try? fm.removeItem(at: file)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var shortcutAction: String?

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            shortcutAction = shortcutItem.type
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.shortcutAction = shortcutItem.type
        }
        completionHandler(true)
    }
}
