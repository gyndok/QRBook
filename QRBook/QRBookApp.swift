import SwiftUI
import SwiftData
import UIKit
import CoreSpotlight

@main
struct QRBookApp: App {
    /// QRCode/Folder sync via CloudKit; ScanEvent lives in a separate
    /// local-only store. Scan history is per-device telemetry that grows on
    /// every view — syncing it to CloudKit floods the mirror with unbounded
    /// writes (which saturated the store and stalled sync). A local-only
    /// fallback for the synced store keeps the app launchable when the
    /// CloudKit container is unavailable (no provisioning, simulator, etc.).
    private static let sharedModelContainer: ModelContainer = {
        let fullSchema = Schema([QRCode.self, Folder.self, ScanEvent.self])
        let scanHistoryConfig = ModelConfiguration(
            "ScanHistory",
            schema: Schema([ScanEvent.self]),
            cloudKitDatabase: .none
        )
        do {
            let cloud = ModelConfiguration(
                schema: Schema([QRCode.self, Folder.self]),
                cloudKitDatabase: .private("iCloud.com.gyndok.QRBook")
            )
            return try ModelContainer(for: fullSchema, configurations: cloud, scanHistoryConfig)
        } catch {
            print("QRBookApp: CloudKit store unavailable (\(error)); falling back to local-only store")
            do {
                let local = ModelConfiguration(
                    schema: Schema([QRCode.self, Folder.self]),
                    cloudKitDatabase: .none
                )
                return try ModelContainer(for: fullSchema, configurations: local, scanHistoryConfig)
            } catch {
                fatalError("Unable to create model container: \(error)")
            }
        }
    }()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true
    @State private var router = DeepLinkRouter.shared
    @State private var storeManager = StoreManager()
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
                    .environment(storeManager)
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
                // onChange doesn't fire for a value set before the view
                // appeared (cold launch from a quick action).
                if let action = appDelegate.shortcutAction {
                    router.handleQuickAction(action)
                    appDelegate.shortcutAction = nil
                }
                Task { await storeManager.checkEntitlement() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
            .onChange(of: scenePhase) { _, phase in
                // Shares can arrive while the app is suspended; re-check every
                // time we come to the foreground, not just on cold launch.
                if phase == .active {
                    checkPendingShareImports()
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
        .modelContainer(Self.sharedModelContainer)
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

        // Handle one share per pass: the router holds a single pending share,
        // so processing them all here would overwrite and lose all but the
        // last. Remaining files are picked up on the next foreground pass.
        // (onAppear and the initial scenePhase transition both call this at
        // launch, hence the pending guard.)
        guard router.pendingShareData == nil else { return }
        for file in files where file.lastPathComponent.hasPrefix("shared-import-") {
            if let data = try? Data(contentsOf: file),
               let payload = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let qrData = payload["data"],
               let typeStr = payload["type"] {
                router.handlePendingShare(data: qrData, type: typeStr)
                try? fm.removeItem(at: file)
                break
            } else {
                // Unreadable/corrupt payload — remove so it can't wedge the queue.
                try? fm.removeItem(at: file)
            }
        }

        for file in files where file.lastPathComponent.hasPrefix("shared-pdf-") {
            router.handlePendingPDF(url: file)
            // Don't delete yet — PDFImportView will handle cleanup after scanning
            break  // Handle one at a time
        }
    }
}

// ObservableObject conformance is required for @UIApplicationDelegateAdaptor
// to publish changes; without it, .onChange(of: shortcutAction) never fires.
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    @Published var shortcutAction: String?

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
