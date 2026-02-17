import XCTest
@testable import QRBook

final class QRCreationViewModelTests: XCTestCase {

    var vm: QRCreationViewModel!

    override func setUp() {
        super.setUp()
        vm = QRCreationViewModel()
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    // MARK: - validate() — title

    func test_validate_emptyTitle_fails() {
        vm.title = ""
        vm.selectedType = .text
        vm.data = "Some text"
        XCTAssertFalse(vm.validate())
        XCTAssertNotNil(vm.validationError)
    }

    // MARK: - validate() — URL type

    func test_validate_urlType_validURL_succeeds() {
        vm.title = "My Link"
        vm.selectedType = .url
        vm.data = "https://example.com"
        XCTAssertTrue(vm.validate())
        XCTAssertNil(vm.validationError)
    }

    func test_validate_urlType_emptyData_fails() {
        vm.title = "My Link"
        vm.selectedType = .url
        vm.data = ""
        XCTAssertFalse(vm.validate())
    }

    // MARK: - validate() — Text type

    func test_validate_textType_validText_succeeds() {
        vm.title = "Note"
        vm.selectedType = .text
        vm.data = "Hello world"
        XCTAssertTrue(vm.validate())
    }

    func test_validate_textType_emptyData_fails() {
        vm.title = "Note"
        vm.selectedType = .text
        vm.data = ""
        XCTAssertFalse(vm.validate())
    }

    // MARK: - validate() — WiFi type

    func test_validate_wifiType_validSSID_succeeds() {
        vm.title = "Home WiFi"
        vm.selectedType = .wifi
        vm.wifiData = WiFiData(ssid: "MyNetwork", password: "pass", security: .WPA)
        XCTAssertTrue(vm.validate())
    }

    func test_validate_wifiType_emptySSID_fails() {
        vm.title = "WiFi"
        vm.selectedType = .wifi
        vm.wifiData = WiFiData(ssid: "", password: "pass", security: .WPA)
        XCTAssertFalse(vm.validate())
    }

    // MARK: - validate() — Contact type

    func test_validate_contactType_validName_succeeds() {
        vm.title = "Contact"
        vm.selectedType = .contact
        vm.contactData = ContactData(name: "John Doe")
        XCTAssertTrue(vm.validate())
    }

    func test_validate_contactType_emptyName_fails() {
        vm.title = "Contact"
        vm.selectedType = .contact
        vm.contactData = ContactData(name: "")
        XCTAssertFalse(vm.validate())
    }

    // MARK: - validate() — Calendar type

    func test_validate_calendarType_validTitle_succeeds() {
        vm.title = "Event"
        vm.selectedType = .calendar
        vm.calendarData = CalendarEventData(title: "Meeting")
        XCTAssertTrue(vm.validate())
    }

    func test_validate_calendarType_emptyTitle_fails() {
        vm.title = "Event"
        vm.selectedType = .calendar
        vm.calendarData = CalendarEventData(title: "")
        XCTAssertFalse(vm.validate())
    }

    // MARK: - validate() — Payment types

    func test_validate_venmoType_validData_succeeds() {
        vm.title = "Venmo"
        vm.selectedType = .venmo
        vm.data = "johndoe"
        XCTAssertTrue(vm.validate())
    }

    func test_validate_paymentType_emptyData_fails() {
        vm.title = "Payment"
        vm.selectedType = .venmo
        vm.data = ""
        XCTAssertFalse(vm.validate())
    }

    func test_validate_clearsValidationError_onSuccess() {
        vm.title = "Valid"
        vm.selectedType = .text
        vm.data = ""
        _ = vm.validate()
        XCTAssertNotNil(vm.validationError)

        vm.data = "Some text"
        _ = vm.validate()
        XCTAssertNil(vm.validationError)
    }

    // MARK: - generateQRData()

    func test_generateQRData_urlType_normalizesURL() {
        vm.selectedType = .url
        vm.data = "example.com"
        let result = vm.generateQRData()
        XCTAssertEqual(result, "https://example.com")
    }

    func test_generateQRData_wifiType_encodesWiFi() {
        vm.selectedType = .wifi
        vm.wifiData = WiFiData(ssid: "Net", password: "pw", security: .WPA)
        let result = vm.generateQRData()
        XCTAssertTrue(result.hasPrefix("WIFI:"))
        XCTAssertTrue(result.contains("S:Net"))
    }

    func test_generateQRData_contactType_encodesContact() {
        vm.selectedType = .contact
        vm.contactData = ContactData(name: "Jane Doe")
        let result = vm.generateQRData()
        XCTAssertTrue(result.contains("BEGIN:VCARD"))
        XCTAssertTrue(result.contains("FN:Jane Doe"))
    }

    func test_generateQRData_calendarType_encodesCalendar() {
        vm.selectedType = .calendar
        vm.calendarData = CalendarEventData(title: "Lunch")
        let result = vm.generateQRData()
        XCTAssertTrue(result.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(result.contains("SUMMARY:Lunch"))
    }

    func test_generateQRData_venmoType_encodesVenmo() {
        vm.selectedType = .venmo
        vm.data = "johndoe"
        let result = vm.generateQRData()
        XCTAssertEqual(result, "https://venmo.com/johndoe")
    }

    func test_generateQRData_textType_returnsDataAsIs() {
        vm.selectedType = .text
        vm.data = "Hello world"
        let result = vm.generateQRData()
        XCTAssertEqual(result, "Hello world")
    }

    func test_generateQRData_cryptoType_returnsDataAsIs() {
        vm.selectedType = .crypto
        vm.data = "bc1qwalletaddress"
        let result = vm.generateQRData()
        XCTAssertEqual(result, "bc1qwalletaddress")
    }

    // MARK: - addTag()

    func test_addTag_validTag_addsToArray() {
        vm.newTag = "work"
        vm.addTag()
        XCTAssertEqual(vm.tags, ["work"])
    }

    func test_addTag_emptyTag_doesNotAdd() {
        vm.newTag = ""
        vm.addTag()
        XCTAssertTrue(vm.tags.isEmpty)
    }

    func test_addTag_invalidTag_doesNotAdd() {
        vm.newTag = "bad!tag"
        vm.addTag()
        XCTAssertTrue(vm.tags.isEmpty)
    }

    func test_addTag_duplicateTag_doesNotAdd() {
        vm.tags = ["work"]
        vm.newTag = "work"
        vm.addTag()
        XCTAssertEqual(vm.tags.count, 1)
    }

    func test_addTag_clearsNewTag_afterAdding() {
        vm.newTag = "personal"
        vm.addTag()
        XCTAssertEqual(vm.newTag, "")
    }

    func test_addTag_whitespaceTag_doesNotAdd() {
        vm.newTag = "   "
        vm.addTag()
        XCTAssertTrue(vm.tags.isEmpty)
    }

    // MARK: - removeTag()

    func test_removeTag_existingTag_removes() {
        vm.tags = ["work", "personal"]
        vm.removeTag("work")
        XCTAssertEqual(vm.tags, ["personal"])
    }

    func test_removeTag_nonexistentTag_noEffect() {
        vm.tags = ["work"]
        vm.removeTag("missing")
        XCTAssertEqual(vm.tags, ["work"])
    }
}
