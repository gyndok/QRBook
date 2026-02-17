import XCTest
@testable import QRBook

final class ValidationTests: XCTestCase {

    // MARK: - validateTitle

    func test_validateTitle_emptyString_returnsError() {
        XCTAssertNotNil(Validation.validateTitle(""))
    }

    func test_validateTitle_whitespaceOnly_returnsError() {
        XCTAssertNotNil(Validation.validateTitle("   "))
    }

    func test_validateTitle_validTitle_returnsNil() {
        XCTAssertNil(Validation.validateTitle("My QR Code"))
    }

    func test_validateTitle_exactly200Chars_returnsNil() {
        let title = String(repeating: "a", count: 200)
        XCTAssertNil(Validation.validateTitle(title))
    }

    func test_validateTitle_201Chars_returnsError() {
        let title = String(repeating: "a", count: 201)
        XCTAssertNotNil(Validation.validateTitle(title))
    }

    func test_validateTitle_errorMessageMentionsTitle() {
        let error = Validation.validateTitle("")
        XCTAssertTrue(error?.lowercased().contains("title") ?? false)
    }

    // MARK: - validateURL

    func test_validateURL_emptyString_returnsError() {
        XCTAssertNotNil(Validation.validateURL(""))
    }

    func test_validateURL_whitespaceOnly_returnsError() {
        XCTAssertNotNil(Validation.validateURL("   "))
    }

    func test_validateURL_validHTTPS_returnsNil() {
        XCTAssertNil(Validation.validateURL("https://example.com"))
    }

    func test_validateURL_validHTTP_returnsNil() {
        XCTAssertNil(Validation.validateURL("http://example.com"))
    }

    func test_validateURL_withoutScheme_returnsNil() {
        XCTAssertNil(Validation.validateURL("example.com"))
    }

    func test_validateURL_tooLong_returnsError() {
        let url = "https://example.com/" + String(repeating: "a", count: 2048)
        XCTAssertNotNil(Validation.validateURL(url))
    }

    // MARK: - normalizeURL

    func test_normalizeURL_withHTTPS_unchanged() {
        XCTAssertEqual(Validation.normalizeURL("https://example.com"), "https://example.com")
    }

    func test_normalizeURL_withHTTP_unchanged() {
        XCTAssertEqual(Validation.normalizeURL("http://example.com"), "http://example.com")
    }

    func test_normalizeURL_withoutScheme_addsHTTPS() {
        XCTAssertEqual(Validation.normalizeURL("example.com"), "https://example.com")
    }

    func test_normalizeURL_trimsWhitespace() {
        XCTAssertEqual(Validation.normalizeURL("  example.com  "), "https://example.com")
    }

    func test_normalizeURL_httpsPrefix_preserved() {
        XCTAssertTrue(Validation.normalizeURL("google.com").hasPrefix("https://"))
    }

    // MARK: - validateText

    func test_validateText_emptyString_returnsError() {
        XCTAssertNotNil(Validation.validateText(""))
    }

    func test_validateText_validText_returnsNil() {
        XCTAssertNil(Validation.validateText("Hello, World!"))
    }

    func test_validateText_exactly4296Chars_returnsNil() {
        let text = String(repeating: "a", count: 4296)
        XCTAssertNil(Validation.validateText(text))
    }

    func test_validateText_tooLong_returnsError() {
        let text = String(repeating: "a", count: 4297)
        XCTAssertNotNil(Validation.validateText(text))
    }

    func test_validateText_whitespaceOnly_returnsError() {
        XCTAssertNotNil(Validation.validateText("   \n\t  "))
    }

    // MARK: - validateTag

    func test_validateTag_emptyString_returnsError() {
        XCTAssertNotNil(Validation.validateTag(""))
    }

    func test_validateTag_validTag_returnsNil() {
        XCTAssertNil(Validation.validateTag("work"))
    }

    func test_validateTag_tooLong_returnsError() {
        let tag = String(repeating: "a", count: 51)
        XCTAssertNotNil(Validation.validateTag(tag))
    }

    func test_validateTag_exactly50Chars_returnsNil() {
        let tag = String(repeating: "a", count: 50)
        XCTAssertNil(Validation.validateTag(tag))
    }

    func test_validateTag_specialChars_returnsError() {
        XCTAssertNotNil(Validation.validateTag("hello!@#"))
    }

    func test_validateTag_hyphenAllowed_returnsNil() {
        XCTAssertNil(Validation.validateTag("my-tag"))
    }

    func test_validateTag_underscoreAllowed_returnsNil() {
        XCTAssertNil(Validation.validateTag("my_tag"))
    }

    func test_validateTag_spacesAllowed_returnsNil() {
        XCTAssertNil(Validation.validateTag("my tag"))
    }

    func test_validateTag_numbersAllowed_returnsNil() {
        XCTAssertNil(Validation.validateTag("tag123"))
    }

    // MARK: - validateRequired

    func test_validateRequired_emptyString_returnsError() {
        XCTAssertNotNil(Validation.validateRequired("", fieldName: "Name"))
    }

    func test_validateRequired_whitespaceOnly_returnsError() {
        XCTAssertNotNil(Validation.validateRequired("   ", fieldName: "Name"))
    }

    func test_validateRequired_validValue_returnsNil() {
        XCTAssertNil(Validation.validateRequired("John", fieldName: "Name"))
    }

    func test_validateRequired_errorContainsFieldName() {
        let error = Validation.validateRequired("", fieldName: "Email")
        XCTAssertTrue(error?.contains("Email") ?? false)
    }
}
