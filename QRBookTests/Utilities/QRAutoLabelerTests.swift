import XCTest
@testable import QRBook

final class QRAutoLabelerTests: XCTestCase {

    // MARK: - Type Detection

    func test_detectType_url() {
        XCTAssertEqual(QRAutoLabeler.detectType("https://example.com"), .url)
        XCTAssertEqual(QRAutoLabeler.detectType("http://example.com"), .url)
    }

    func test_detectType_wifi() {
        XCTAssertEqual(QRAutoLabeler.detectType("WIFI:T:WPA;S:MyNet;P:pass;;"), .wifi)
    }

    func test_detectType_contact() {
        XCTAssertEqual(QRAutoLabeler.detectType("BEGIN:VCARD\nFN:John\nEND:VCARD"), .contact)
    }

    func test_detectType_calendar() {
        XCTAssertEqual(QRAutoLabeler.detectType("BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:Test\nEND:VEVENT\nEND:VCALENDAR"), .calendar)
    }

    func test_detectType_venmo() {
        XCTAssertEqual(QRAutoLabeler.detectType("https://venmo.com/johndoe"), .venmo)
    }

    func test_detectType_paypal() {
        XCTAssertEqual(QRAutoLabeler.detectType("https://www.paypal.com/paypalme/johndoe"), .paypal)
    }

    func test_detectType_cashapp() {
        XCTAssertEqual(QRAutoLabeler.detectType("https://cash.app/$johndoe"), .cashapp)
    }

    func test_detectType_zelle() {
        XCTAssertEqual(QRAutoLabeler.detectType("Zelle: john@example.com"), .zelle)
    }

    func test_detectType_plainText() {
        XCTAssertEqual(QRAutoLabeler.detectType("just some text"), .text)
    }

    // MARK: - Title Suggestion

    func test_label_url_usesDomain() {
        let label = QRAutoLabeler.label(payload: "https://www.united.com/checkin/bp?conf=ABC")
        XCTAssertEqual(label.suggestedTitle, "united.com")
        XCTAssertEqual(label.detectedType, .url)
    }

    func test_label_wifi_usesSSID() {
        let label = QRAutoLabeler.label(payload: "WIFI:T:WPA;S:CoffeeShop;P:latte123;;")
        XCTAssertEqual(label.suggestedTitle, "Wi-Fi: CoffeeShop")
        XCTAssertEqual(label.detectedType, .wifi)
    }

    func test_label_contact_usesName() {
        let label = QRAutoLabeler.label(payload: "BEGIN:VCARD\nVERSION:3.0\nFN:Jane Smith\nEND:VCARD")
        XCTAssertEqual(label.suggestedTitle, "Jane Smith")
        XCTAssertEqual(label.detectedType, .contact)
    }

    func test_label_calendar_usesEventTitle() {
        let label = QRAutoLabeler.label(payload: "BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:Board Meeting\nEND:VEVENT\nEND:VCALENDAR")
        XCTAssertEqual(label.suggestedTitle, "Board Meeting")
        XCTAssertEqual(label.detectedType, .calendar)
    }

    func test_label_venmo_usesUsername() {
        let label = QRAutoLabeler.label(payload: "https://venmo.com/johndoe")
        XCTAssertEqual(label.suggestedTitle, "Venmo: johndoe")
    }

    func test_label_plainText_short_usesFullText() {
        let label = QRAutoLabeler.label(payload: "Hello World")
        XCTAssertEqual(label.suggestedTitle, "Hello World")
    }

    func test_label_plainText_long_truncates() {
        let longText = String(repeating: "A", count: 50)
        let label = QRAutoLabeler.label(payload: longText)
        XCTAssertTrue(label.suggestedTitle.hasSuffix("..."))
        XCTAssertTrue(label.suggestedTitle.count <= 40)
    }

    // MARK: - Tag Suggestion

    func test_label_travelURL_suggestsTravelTag() {
        let label = QRAutoLabeler.label(payload: "https://www.united.com/checkin")
        XCTAssertEqual(label.suggestedTags, ["travel"])
    }

    func test_label_ticketURL_suggestsTicketsTag() {
        let label = QRAutoLabeler.label(payload: "https://www.eventbrite.com/e/123")
        XCTAssertEqual(label.suggestedTags, ["tickets"])
    }

    func test_label_wifi_suggestsWifiTag() {
        let label = QRAutoLabeler.label(payload: "WIFI:T:WPA;S:Net;P:pass;;")
        XCTAssertEqual(label.suggestedTags, ["wifi"])
    }

    func test_label_payment_suggestsPaymentTag() {
        let label = QRAutoLabeler.label(payload: "https://venmo.com/johndoe")
        XCTAssertEqual(label.suggestedTags, ["payment"])
    }

    func test_label_genericURL_noTags() {
        let label = QRAutoLabeler.label(payload: "https://example.com/page")
        XCTAssertTrue(label.suggestedTags.isEmpty)
    }
}
