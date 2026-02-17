import XCTest
import SwiftUI
@testable import QRBook

final class ColorHexTests: XCTestCase {

    // MARK: - Color(hex:) init

    func test_initHex_sixDigitHex_createsColor() {
        let color = Color(hex: "FF0000")
        XCTAssertNotNil(color)
    }

    func test_initHex_withHashPrefix_parsesCorrectly() {
        let color = Color(hex: "#00FF00")
        XCTAssertNotNil(color)
    }

    func test_initHex_red_matchesExpected() {
        let color = Color(hex: "FF0000")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1.0, accuracy: 0.01)
        XCTAssertEqual(g, 0.0, accuracy: 0.01)
        XCTAssertEqual(b, 0.0, accuracy: 0.01)
    }

    func test_initHex_green_matchesExpected() {
        let color = Color(hex: "00FF00")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0.0, accuracy: 0.01)
        XCTAssertEqual(g, 1.0, accuracy: 0.01)
        XCTAssertEqual(b, 0.0, accuracy: 0.01)
    }

    func test_initHex_blue_matchesExpected() {
        let color = Color(hex: "0000FF")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0.0, accuracy: 0.01)
        XCTAssertEqual(g, 0.0, accuracy: 0.01)
        XCTAssertEqual(b, 1.0, accuracy: 0.01)
    }

    func test_initHex_black_matchesExpected() {
        let color = Color(hex: "000000")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0.0, accuracy: 0.01)
        XCTAssertEqual(g, 0.0, accuracy: 0.01)
        XCTAssertEqual(b, 0.0, accuracy: 0.01)
    }

    func test_initHex_white_matchesExpected() {
        let color = Color(hex: "FFFFFF")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1.0, accuracy: 0.01)
        XCTAssertEqual(g, 1.0, accuracy: 0.01)
        XCTAssertEqual(b, 1.0, accuracy: 0.01)
    }

    // MARK: - AccentTheme

    func test_AccentTheme_allCases_haveNonEmptyLabel() {
        for theme in Color.AccentTheme.allCases {
            XCTAssertFalse(theme.label.isEmpty, "\(theme.rawValue) has empty label")
        }
    }

    func test_AccentTheme_allCasesCount() {
        XCTAssertEqual(Color.AccentTheme.allCases.count, 6)
    }

    func test_AccentTheme_companionHex_differsFromRawValue() {
        for theme in Color.AccentTheme.allCases {
            XCTAssertNotEqual(theme.rawValue, theme.companionHex, "\(theme.label) has same primary and companion hex")
        }
    }

    func test_AccentTheme_violetHex() {
        XCTAssertEqual(Color.AccentTheme.violet.rawValue, "7C3AED")
    }

    func test_AccentTheme_labels() {
        XCTAssertEqual(Color.AccentTheme.violet.label, "Violet")
        XCTAssertEqual(Color.AccentTheme.indigo.label, "Indigo")
        XCTAssertEqual(Color.AccentTheme.teal.label, "Teal")
        XCTAssertEqual(Color.AccentTheme.rose.label, "Rose")
        XCTAssertEqual(Color.AccentTheme.orange.label, "Orange")
        XCTAssertEqual(Color.AccentTheme.mono.label, "Mono")
    }
}
