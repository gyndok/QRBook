import SwiftUI
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var favorites: [[String: String]] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        loadCached()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["favorites"] as? Data,
           let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
            DispatchQueue.main.async {
                self.favorites = items
                self.saveCached(items)
            }
        }
    }

    private func loadCached() {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("favorites.json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else { return }
        favorites = items
    }

    private func saveCached(_ items: [[String: String]]) {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("favorites.json"),
              let data = try? JSONSerialization.data(withJSONObject: items) else { return }
        try? data.write(to: url)
    }
}

struct FavoritesListView: View {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites",
                        systemImage: "star",
                        description: Text("Favorite QR codes on your iPhone to see them here.")
                    )
                } else {
                    List(sessionManager.favorites, id: \.["id"]) { item in
                        NavigationLink {
                            WatchQRFullscreenView(data: item["data"] ?? "", title: item["title"] ?? "")
                        } label: {
                            Text(item["title"] ?? "QR Code")
                        }
                    }
                }
            }
            .navigationTitle("QR Book")
        }
    }
}
