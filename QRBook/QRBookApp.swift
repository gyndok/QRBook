import SwiftUI
import SwiftData

@main
struct QRBookApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: QRCode.self)
    }
}
