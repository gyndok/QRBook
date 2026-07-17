import SwiftData
import XCTest
@testable import QRBook

final class QRCodeModelTests: XCTestCase {

    // MARK: - ScanEvent history capping

    @MainActor
    func test_scanEvent_record_prunesToLimit() throws {
        let container = try ModelContainer(
            for: ScanEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let codeId = UUID()
        let otherId = UUID()

        for _ in 0..<10 {
            ScanEvent.record(qrCodeId: codeId, in: context, keeping: 5)
        }
        ScanEvent.record(qrCodeId: otherId, in: context, keeping: 5)

        let forCode = try context.fetch(
            FetchDescriptor<ScanEvent>(predicate: #Predicate { $0.qrCodeId == codeId })
        )
        XCTAssertEqual(forCode.count, 5, "history should be capped per code")

        let forOther = try context.fetch(
            FetchDescriptor<ScanEvent>(predicate: #Predicate { $0.qrCodeId == otherId })
        )
        XCTAssertEqual(forOther.count, 1, "pruning one code must not affect another")
    }

    @MainActor
    func test_scanEvent_record_underLimit_keepsAll() throws {
        let container = try ModelContainer(
            for: ScanEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let codeId = UUID()
        for _ in 0..<3 {
            ScanEvent.record(qrCodeId: codeId, in: context, keeping: 5)
        }
        let events = try context.fetch(
            FetchDescriptor<ScanEvent>(predicate: #Predicate { $0.qrCodeId == codeId })
        )
        XCTAssertEqual(events.count, 3)
    }

    // MARK: - QRType enum

    func test_QRType_allCases_haveNonEmptyLabel() {
        for type in QRType.allCases {
            XCTAssertFalse(type.label.isEmpty, "\(type.rawValue) has empty label")
        }
    }

    func test_QRType_allCases_haveNonEmptyIcon() {
        for type in QRType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type.rawValue) has empty icon")
        }
    }

    func test_QRType_allCases_haveNonEmptyDescription() {
        for type in QRType.allCases {
            XCTAssertFalse(type.description.isEmpty, "\(type.rawValue) has empty description")
        }
    }

    func test_QRType_urlRawValue() {
        XCTAssertEqual(QRType.url.rawValue, "url")
    }

    func test_QRType_urlLabel() {
        XCTAssertEqual(QRType.url.label, "URL")
    }

    func test_QRType_wifiLabel() {
        XCTAssertEqual(QRType.wifi.label, "Wi-Fi")
    }

    func test_QRType_allCasesCount() {
        XCTAssertEqual(QRType.allCases.count, 11)
    }

    // MARK: - ErrorCorrectionLevel enum

    func test_ErrorCorrectionLevel_allCases_haveCorrectLabels() {
        XCTAssertEqual(ErrorCorrectionLevel.L.label, "Low (7%)")
        XCTAssertEqual(ErrorCorrectionLevel.M.label, "Medium (15%)")
        XCTAssertEqual(ErrorCorrectionLevel.Q.label, "Quartile (25%)")
        XCTAssertEqual(ErrorCorrectionLevel.H.label, "High (30%)")
    }

    func test_ErrorCorrectionLevel_allCasesCount() {
        XCTAssertEqual(ErrorCorrectionLevel.allCases.count, 4)
    }

    // MARK: - QRCode tags property

    func test_tags_emptyTagsRaw_returnsEmptyArray() {
        let qr = TestData.makeQRCode(tags: [])
        XCTAssertEqual(qr.tags, [])
    }

    func test_tags_multipleTags_returnsSplitArray() {
        let qr = TestData.makeQRCode(tags: ["work", "personal"])
        XCTAssertEqual(qr.tags, ["work", "personal"])
    }

    func test_tags_setter_joinsWithComma() {
        let qr = TestData.makeQRCode()
        qr.tags = ["a", "b", "c"]
        XCTAssertEqual(qr.tagsRaw, "a,b,c")
    }

    func test_tags_getter_trimsWhitespace() {
        let qr = TestData.makeQRCode()
        qr.tagsRaw = "work , personal , fun"
        let tags = qr.tags
        XCTAssertEqual(tags, ["work", "personal", "fun"])
    }

    // MARK: - QRCode type property

    func test_type_validRaw_returnsCorrectEnum() {
        let qr = TestData.makeQRCode(type: .wifi)
        XCTAssertEqual(qr.type, .wifi)
    }

    func test_type_invalidRaw_defaultsToText() {
        let qr = TestData.makeQRCode()
        qr.typeRaw = "invalid_type"
        XCTAssertEqual(qr.type, .text)
    }

    func test_type_setter_updatesRaw() {
        let qr = TestData.makeQRCode()
        qr.type = .contact
        XCTAssertEqual(qr.typeRaw, "contact")
    }

    // MARK: - QRCode errorCorrection property

    func test_errorCorrection_validRaw_returnsCorrectEnum() {
        let qr = TestData.makeQRCode()
        XCTAssertEqual(qr.errorCorrection, .M)
    }

    func test_errorCorrection_invalidRaw_defaultsToM() {
        let qr = TestData.makeQRCode()
        qr.errorCorrectionRaw = "INVALID"
        XCTAssertEqual(qr.errorCorrection, .M)
    }

    func test_errorCorrection_setter_updatesRaw() {
        let qr = TestData.makeQRCode()
        qr.errorCorrection = .H
        XCTAssertEqual(qr.errorCorrectionRaw, "H")
    }

    // MARK: - QRCode init

    func test_init_setsAllProperties() {
        let id = UUID()
        let date = Date()
        let qr = QRCode(
            id: id,
            title: "Test",
            data: "https://test.com",
            type: .url,
            tags: ["tag1"],
            isFavorite: true,
            errorCorrection: .H,
            sizePx: 256,
            createdAt: date,
            folderName: "Work"
        )
        XCTAssertEqual(qr.id, id)
        XCTAssertEqual(qr.title, "Test")
        XCTAssertEqual(qr.data, "https://test.com")
        XCTAssertEqual(qr.type, .url)
        XCTAssertEqual(qr.tags, ["tag1"])
        XCTAssertTrue(qr.isFavorite)
        XCTAssertEqual(qr.errorCorrection, .H)
        XCTAssertEqual(qr.sizePx, 256)
        XCTAssertEqual(qr.createdAt, date)
        XCTAssertEqual(qr.folderName, "Work")
    }
}
