import SwiftUI
import SwiftData

@main
struct QRBookApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .tint(Color.electricViolet)
        }
        .modelContainer(for: QRCode.self)
    }
}
