import SwiftUI

@Observable
class DeepLinkRouter {
    /// Single shared instance so App Intents (which run in-process) can route
    /// into the same router the view hierarchy observes.
    static let shared = DeepLinkRouter()

    var selectedTab: MainTabView.Tab = .library
    var showQRCodeId: UUID?
    var showCreateSheet = false
    var pendingShareData: String?
    var pendingShareType: String?
    var pendingPDFURL: URL?

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

    func handlePendingPDF(url: URL) {
        pendingPDFURL = url
        selectedTab = .scan
    }

    func handlePendingShare(data: String, type: String) {
        pendingShareData = data
        pendingShareType = type
        selectedTab = .library
        showCreateSheet = true
    }
}
