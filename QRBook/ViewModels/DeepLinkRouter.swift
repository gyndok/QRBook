import SwiftUI

@Observable
class DeepLinkRouter {
    var selectedTab: MainTabView.Tab = .library
    var showQRCodeId: UUID?
    var showCreateSheet = false

    func handleQuickAction(_ shortcutType: String) {
        switch shortcutType {
        case "CreateQR":
            selectedTab = .library
            showCreateSheet = true
        case "ScanQR":
            selectedTab = .scan
        case "Favorites":
            selectedTab = .favorites
        default:
            break
        }
    }

    func showQRCode(id: UUID) {
        selectedTab = .library
        showQRCodeId = id
    }
}
