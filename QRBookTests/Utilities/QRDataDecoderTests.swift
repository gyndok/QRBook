import XCTest
@testable import QRBook

final class QRDataDecoderTests: XCTestCase {

    // MARK: - decodeWiFi

    func test_decodeWiFi_validWPA_returnsWiFiData() {
        let data = "WIFI:T:WPA;S:MyNetwork;P:password123;H:false;;"
        let result = QRDataDecoder.decodeWiFi(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.ssid, "MyNetwork")
        XCTAssertEqual(result?.password, "password123")
        XCTAssertEqual(result?.security, .WPA)
        XCTAssertFalse(result?.hidden ?? true)
    }

    func test_decodeWiFi_validWEP_returnsWiFiData() {
        let data = "WIFI:T:WEP;S:OldNetwork;P:wepkey;H:false;;"
        let result = QRDataDecoder.decodeWiFi(from: data)
        XCTAssertEqual(result?.security, .WEP)
    }

    func test_decodeWiFi_nopass_returnsWiFiData() {
        let data = "WIFI:T:nopass;S:OpenNetwork;P:;H:false;;"
        let result = QRDataDecoder.decodeWiFi(from: data)
        XCTAssertEqual(result?.security, .nopass)
        XCTAssertEqual(result?.password, "")
    }

    func test_decodeWiFi_hiddenNetwork_setsHiddenTrue() {
        let data = "WIFI:T:WPA;S:Hidden;P:pass;H:true;;"
        let result = QRDataDecoder.decodeWiFi(from: data)
        XCTAssertTrue(result?.hidden ?? false)
    }

    func test_decodeWiFi_invalidPrefix_returnsNil() {
        let result = QRDataDecoder.decodeWiFi(from: "NOT_WIFI:data")
        XCTAssertNil(result)
    }

    func test_decodeWiFi_missingFields_usesDefaults() {
        let data = "WIFI:S:JustSSID;;"
        let result = QRDataDecoder.decodeWiFi(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.ssid, "JustSSID")
        XCTAssertEqual(result?.security, .WPA)
        XCTAssertFalse(result?.hidden ?? true)
    }

    // MARK: - decodeContact

    func test_decodeContact_validVCard_returnsContactData() {
        let data = """
        BEGIN:VCARD
        VERSION:3.0
        FN:John Doe
        TEL;TYPE=CELL:555-1234
        EMAIL:john@example.com
        ORG:Acme Inc
        URL:https://example.com
        END:VCARD
        """
        let result = QRDataDecoder.decodeContact(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "John Doe")
        XCTAssertEqual(result?.phone, "555-1234")
        XCTAssertEqual(result?.email, "john@example.com")
        XCTAssertEqual(result?.organization, "Acme Inc")
        XCTAssertEqual(result?.url, "https://example.com")
    }

    func test_decodeContact_nameOnly_returnsPartialContact() {
        let data = "BEGIN:VCARD\nVERSION:3.0\nFN:Jane\nEND:VCARD"
        let result = QRDataDecoder.decodeContact(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Jane")
        XCTAssertEqual(result?.phone, "")
        XCTAssertEqual(result?.email, "")
    }

    func test_decodeContact_invalidPrefix_returnsNil() {
        let result = QRDataDecoder.decodeContact(from: "Not a vCard")
        XCTAssertNil(result)
    }

    func test_decodeContact_telWithType_extractsPhoneNumber() {
        let data = "BEGIN:VCARD\nTEL;TYPE=WORK:555-9876\nEND:VCARD"
        let result = QRDataDecoder.decodeContact(from: data)
        XCTAssertEqual(result?.phone, "555-9876")
    }

    // MARK: - decodeCalendarEvent

    func test_decodeCalendarEvent_allDayEvent_parsesCorrectly() {
        let data = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20260315
        DTEND;VALUE=DATE:20260316
        SUMMARY:All Day Event
        END:VEVENT
        END:VCALENDAR
        """
        let result = QRDataDecoder.decodeCalendarEvent(from: data)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.allDay ?? false)
        XCTAssertEqual(result?.title, "All Day Event")
    }

    func test_decodeCalendarEvent_timedEvent_parsesCorrectly() {
        let data = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        DTSTART:20260315T090000
        DTEND:20260315T100000
        SUMMARY:Meeting
        LOCATION:Room 101
        DESCRIPTION:Weekly sync
        END:VEVENT
        END:VCALENDAR
        """
        let result = QRDataDecoder.decodeCalendarEvent(from: data)
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.allDay ?? true)
        XCTAssertEqual(result?.title, "Meeting")
        XCTAssertEqual(result?.location, "Room 101")
        XCTAssertEqual(result?.eventDescription, "Weekly sync")
    }

    func test_decodeCalendarEvent_invalidPrefix_returnsNil() {
        let result = QRDataDecoder.decodeCalendarEvent(from: "Not a calendar event")
        XCTAssertNil(result)
    }

    // MARK: - decodePayment

    func test_decodePayment_venmo_extractsUsername() {
        let result = QRDataDecoder.decodePayment(from: "https://venmo.com/johndoe", type: .venmo)
        XCTAssertEqual(result, "johndoe")
    }

    func test_decodePayment_paypal_extractsUsername() {
        let result = QRDataDecoder.decodePayment(from: "https://www.paypal.com/paypalme/johndoe", type: .paypal)
        XCTAssertEqual(result, "johndoe")
    }

    func test_decodePayment_cashapp_extractsCashtag() {
        let result = QRDataDecoder.decodePayment(from: "https://cash.app/$johndoe", type: .cashapp)
        XCTAssertEqual(result, "johndoe")
    }

    func test_decodePayment_zelle_extractsContact() {
        let result = QRDataDecoder.decodePayment(from: "Zelle: john@example.com", type: .zelle)
        XCTAssertEqual(result, "john@example.com")
    }

    func test_decodePayment_unsupportedType_returnsOriginal() {
        let result = QRDataDecoder.decodePayment(from: "some data", type: .text)
        XCTAssertEqual(result, "some data")
    }

    // MARK: - Round-trip tests

    func test_roundTrip_wifi_encodeAndDecode() {
        let original = TestData.makeWiFiData(ssid: "TestNet", password: "secret", security: .WPA, hidden: true)
        let encoded = QRDataEncoder.encodeWiFi(original)
        let decoded = QRDataDecoder.decodeWiFi(from: encoded)
        XCTAssertEqual(decoded?.ssid, original.ssid)
        XCTAssertEqual(decoded?.password, original.password)
        XCTAssertEqual(decoded?.security, original.security)
        XCTAssertEqual(decoded?.hidden, original.hidden)
    }

    func test_roundTrip_contact_encodeAndDecode() {
        let original = TestData.makeContactData()
        let encoded = QRDataEncoder.encodeContact(original)
        let decoded = QRDataDecoder.decodeContact(from: encoded)
        XCTAssertEqual(decoded?.name, original.name)
        XCTAssertEqual(decoded?.phone, original.phone)
        XCTAssertEqual(decoded?.email, original.email)
        XCTAssertEqual(decoded?.organization, original.organization)
        XCTAssertEqual(decoded?.url, original.url)
    }

    func test_roundTrip_venmo_encodeAndDecode() {
        let encoded = QRDataEncoder.encodeVenmo("johndoe")
        let decoded = QRDataDecoder.decodePayment(from: encoded, type: .venmo)
        XCTAssertEqual(decoded, "johndoe")
    }
}
