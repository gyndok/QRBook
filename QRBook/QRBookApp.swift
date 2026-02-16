import SwiftUI
import SwiftData

@main
struct QRBookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: QRCode.self)
    }
}
