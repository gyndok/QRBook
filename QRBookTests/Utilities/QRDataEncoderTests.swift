import XCTest
@testable import QRBook

final class QRDataEncoderTests: XCTestCase {

    // MARK: - encodeWiFi

    func test_encodeWiFi_WPA_generatesCorrectFormat() {
        let wifi = TestData.makeWiFiData(ssid: "Home", password: "pass123", security: .WPA)
        let result = QRDataEncoder.encodeWiFi(wifi)
        XCTAssertEqual(result, "WIFI:T:WPA;S:Home;P:pass123;H:false;;")
    }

    func test_encodeWiFi_WEP_generatesCorrectFormat() {
        let wifi = TestData.makeWiFiData(security: .WEP)
        let result = QRDataEncoder.encodeWiFi(wifi)
        XCTAssertTrue(result.contains("T:WEP"))
    }

    func test_encodeWiFi_nopass_generatesCorrectFormat() {
        let wifi = TestData.makeWiFiData(password: "", security: .nopass)
        let result = QRDataEncoder.encodeWiFi(wifi)
        XCTAssertTrue(result.contains("T:nopass"))
        XCTAssertTrue(result.contains("P:"))
    }

    func test_encodeWiFi_hiddenNetwork_setsHiddenTrue() {
        let wifi = TestData.makeWiFiData(hidden: true)
        let result = QRDataEncoder.encodeWiFi(wifi)
        XCTAssertTrue(result.contains("H:true"))
    }

    func test_encodeWiFi_visibleNetwork_setsHiddenFalse() {
        let wifi = TestData.makeWiFiData(hidden: false)
        let result = QRDataEncoder.encodeWiFi(wifi)
        XCTAssertTrue(result.contains("H:false"))
    }

    func test_encodeWiFi_specialCharsInSSID_encodesCorrectly() {
        let wifi = TestData.makeWiFiData(ssid: "My WiFi: \"Best\"")
        let result = QRDataEncoder.encodeWiFi(wifi)
        XCTAssertTrue(result.contains("S:My WiFi: \"Best\""))
    }

    func test_encodeWiFi_startsWithWIFI() {
        let wifi = TestData.makeWiFiData()
        let result = QRDataEncoder.encodeWiFi(wifi)
        XCTAssertTrue(result.hasPrefix("WIFI:"))
    }

    // MARK: - encodeContact

    func test_encodeContact_allFields_generatesValidVCard() {
        let contact = TestData.makeContactData()
        let result = QRDataEncoder.encodeContact(contact)
        XCTAssertTrue(result.contains("BEGIN:VCARD"))
        XCTAssertTrue(result.contains("VERSION:3.0"))
        XCTAssertTrue(result.contains("FN:John Doe"))
        XCTAssertTrue(result.contains("TEL;TYPE=CELL:555-1234"))
        XCTAssertTrue(result.contains("EMAIL:john@example.com"))
        XCTAssertTrue(result.contains("ORG:Acme Inc"))
        XCTAssertTrue(result.contains("URL:https://example.com"))
        XCTAssertTrue(result.contains("END:VCARD"))
    }

    func test_encodeContact_twoWordName_parsesNCorrectly() {
        let contact = TestData.makeContactData(name: "John Doe")
        let result = QRDataEncoder.encodeContact(contact)
        XCTAssertTrue(result.contains("N:Doe;John;;;"))
    }

    func test_encodeContact_singleName_encodesInNField() {
        let contact = TestData.makeContactData(name: "Madonna", phone: "", email: "", organization: "", url: "")
        let result = QRDataEncoder.encodeContact(contact)
        XCTAssertTrue(result.contains("N:Madonna;;;;"))
    }

    func test_encodeContact_nameOnly_omitsEmptyFields() {
        let contact = TestData.makeContactData(name: "Jane", phone: "", email: "", organization: "", url: "")
        let result = QRDataEncoder.encodeContact(contact)
        XCTAssertFalse(result.contains("TEL"))
        XCTAssertFalse(result.contains("EMAIL"))
        XCTAssertFalse(result.contains("ORG"))
        XCTAssertFalse(result.contains("URL"))
    }

    func test_encodeContact_beginsAndEndsCorrectly() {
        let contact = TestData.makeContactData()
        let result = QRDataEncoder.encodeContact(contact)
        let lines = result.components(separatedBy: "\n")
        XCTAssertEqual(lines.first, "BEGIN:VCARD")
        XCTAssertEqual(lines.last, "END:VCARD")
    }

    // MARK: - encodeCalendarEvent

    func test_encodeCalendarEvent_allDayEvent_usesDateFormat() {
        let event = TestData.makeCalendarEventData(allDay: true)
        let result = QRDataEncoder.encodeCalendarEvent(event)
        XCTAssertTrue(result.contains("DTSTART;VALUE=DATE:"))
        XCTAssertTrue(result.contains("DTEND;VALUE=DATE:"))
        XCTAssertFalse(result.contains("DTSTART:"))
    }

    func test_encodeCalendarEvent_timedEvent_usesDateTimeFormat() {
        let event = TestData.makeCalendarEventData(allDay: false)
        let result = QRDataEncoder.encodeCalendarEvent(event)
        XCTAssertTrue(result.contains("DTSTART:"))
        XCTAssertTrue(result.contains("DTEND:"))
        XCTAssertFalse(result.contains("VALUE=DATE"))
    }

    func test_encodeCalendarEvent_includesTitle() {
        let event = TestData.makeCalendarEventData(title: "Birthday Party")
        let result = QRDataEncoder.encodeCalendarEvent(event)
        XCTAssertTrue(result.contains("SUMMARY:Birthday Party"))
    }

    func test_encodeCalendarEvent_includesLocation() {
        let event = TestData.makeCalendarEventData(location: "Conference Room A")
        let result = QRDataEncoder.encodeCalendarEvent(event)
        XCTAssertTrue(result.contains("LOCATION:Conference Room A"))
    }

    func test_encodeCalendarEvent_includesDescription() {
        let event = TestData.makeCalendarEventData(eventDescription: "Bring cake")
        let result = QRDataEncoder.encodeCalendarEvent(event)
        XCTAssertTrue(result.contains("DESCRIPTION:Bring cake"))
    }

    func test_encodeCalendarEvent_omitsEmptyLocation() {
        let event = TestData.makeCalendarEventData(location: "")
        let result = QRDataEncoder.encodeCalendarEvent(event)
        XCTAssertFalse(result.contains("LOCATION:"))
    }

    func test_encodeCalendarEvent_hasCorrectStructure() {
        let event = TestData.makeCalendarEventData()
        let result = QRDataEncoder.encodeCalendarEvent(event)
        XCTAssertTrue(result.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(result.contains("VERSION:2.0"))
        XCTAssertTrue(result.contains("BEGIN:VEVENT"))
        XCTAssertTrue(result.contains("END:VEVENT"))
        XCTAssertTrue(result.contains("END:VCALENDAR"))
    }

    // MARK: - encodeVenmo

    func test_encodeVenmo_usernameWithAt_removesAt() {
        let result = QRDataEncoder.encodeVenmo("@johndoe")
        XCTAssertEqual(result, "https://venmo.com/johndoe")
    }

    func test_encodeVenmo_usernameWithoutAt_works() {
        let result = QRDataEncoder.encodeVenmo("johndoe")
        XCTAssertEqual(result, "https://venmo.com/johndoe")
    }

    func test_encodeVenmo_trimsWhitespace() {
        let result = QRDataEncoder.encodeVenmo("  johndoe  ")
        XCTAssertEqual(result, "https://venmo.com/johndoe")
    }

    // MARK: - encodePayPal

    func test_encodePayPal_email_generatesPayPalMeLink() {
        let result = QRDataEncoder.encodePayPal("john@example.com")
        XCTAssertEqual(result, "https://www.paypal.com/paypalme/john@example.com")
    }

    func test_encodePayPal_username_generatesPayPalMeLink() {
        let result = QRDataEncoder.encodePayPal("johndoe")
        XCTAssertEqual(result, "https://www.paypal.com/paypalme/johndoe")
    }

    // MARK: - encodeCashApp

    func test_encodeCashApp_withDollarSign_removesAndReAdds() {
        let result = QRDataEncoder.encodeCashApp("$johndoe")
        XCTAssertEqual(result, "https://cash.app/$johndoe")
    }

    func test_encodeCashApp_withoutDollarSign_addsDollar() {
        let result = QRDataEncoder.encodeCashApp("johndoe")
        XCTAssertEqual(result, "https://cash.app/$johndoe")
    }

    // MARK: - encodeZelle

    func test_encodeZelle_phone_generatesCorrectFormat() {
        let result = QRDataEncoder.encodeZelle("555-1234")
        XCTAssertEqual(result, "Zelle: 555-1234")
    }

    func test_encodeZelle_email_generatesCorrectFormat() {
        let result = QRDataEncoder.encodeZelle("john@example.com")
        XCTAssertEqual(result, "Zelle: john@example.com")
    }

    func test_encodeZelle_trimsWhitespace() {
        let result = QRDataEncoder.encodeZelle("  john@example.com  ")
        XCTAssertEqual(result, "Zelle: john@example.com")
    }
}
