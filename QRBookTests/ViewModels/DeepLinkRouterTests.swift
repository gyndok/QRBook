import XCTest
@testable import QRBook

final class DeepLinkRouterTests: XCTestCase {

    var router: DeepLinkRouter!

    override func setUp() {
        super.setUp()
        router = DeepLinkRouter()
    }

    override func tearDown() {
        router = nil
        super.tearDown()
    }

    // MARK: - handleQuickAction

    func test_handleQuickAction_CreateQR_setsCorrectState() {
        router.handleQuickAction("CreateQR")
        XCTAssertEqual(router.selectedTab, .library)
        XCTAssertTrue(router.showCreateSheet)
    }

    func test_handleQuickAction_ScanQR_switchesToScanTab() {
        router.handleQuickAction("ScanQR")
        XCTAssertEqual(router.selectedTab, .scan)
    }

    func test_handleQuickAction_Favorites_switchesToFavoritesTab() {
        router.handleQuickAction("Favorites")
        XCTAssertEqual(router.selectedTab, .favorites)
    }

    func test_handleQuickAction_unknown_noStateChange() {
        let originalTab = router.selectedTab
        router.handleQuickAction("UnknownAction")
        XCTAssertEqual(router.selectedTab, originalTab)
        XCTAssertFalse(router.showCreateSheet)
    }

    // MARK: - showQRCode

    func test_showQRCode_setsTabAndID() {
        let id = UUID()
        router.showQRCode(id: id)
        XCTAssertEqual(router.selectedTab, .library)
        XCTAssertEqual(router.showQRCodeId, id)
    }

    // MARK: - handlePendingShare

    func test_handlePendingShare_setsAllState() {
        router.handlePendingShare(data: "https://example.com", type: "url")
        XCTAssertEqual(router.pendingShareData, "https://example.com")
        XCTAssertEqual(router.pendingShareType, "url")
        XCTAssertEqual(router.selectedTab, .library)
        XCTAssertTrue(router.showCreateSheet)
    }
}
