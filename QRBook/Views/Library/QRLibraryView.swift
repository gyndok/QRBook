import SwiftUI
import SwiftData

enum ViewMode {
    case all, favorites, recent
}

struct QRLibraryView: View {
    let viewMode: ViewMode

    @Query(sort: \QRCode.createdAt, order: .reverse) private var qrCodes: [QRCode]

    private var navigationTitle: String {
        switch viewMode {
        case .all: "QR Library"
        case .favorites: "Favorites"
        case .recent: "Recent"
        }
    }

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No QR Codes Yet", systemImage: "qrcode")
            } description: {
                Text("Create your first QR code to get started.")
            }
            .navigationTitle(navigationTitle)
        }
    }
}
