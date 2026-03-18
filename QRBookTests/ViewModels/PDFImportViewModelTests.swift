import XCTest
@testable import QRBook

final class PDFImportViewModelTests: XCTestCase {

    private func makeCandidates() -> [ImportCandidate] {
        let detected1 = DetectedQRCode(
            id: UUID(), payload: "https://example.com", symbology: .qr, pageNumbers: [1]
        )
        let detected2 = DetectedQRCode(
            id: UUID(), payload: "Hello World", symbology: .qr, pageNumbers: [2]
        )
        let label1 = QRAutoLabeler.label(payload: detected1.payload)
        let label2 = QRAutoLabeler.label(payload: detected2.payload)
        return [
            ImportCandidate(from: detected1, label: label1),
            ImportCandidate(from: detected2, label: label2)
        ]
    }

    // MARK: - State

    @MainActor
    func test_initialState_isIdle() {
        let vm = PDFImportViewModel()
        XCTAssertEqual(vm.state, .idle)
        XCTAssertTrue(vm.candidates.isEmpty)
    }

    @MainActor
    func test_reset_returnsToIdle() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        vm.state = .results
        vm.pdfFilename = "test.pdf"

        vm.reset()

        XCTAssertEqual(vm.state, .idle)
        XCTAssertTrue(vm.candidates.isEmpty)
        XCTAssertEqual(vm.pdfFilename, "")
    }

    // MARK: - Selection

    @MainActor
    func test_selectedCount_allSelectedByDefault() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        XCTAssertEqual(vm.selectedCount, 2)
    }

    @MainActor
    func test_toggleSelection_deselectsCandidate() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        let id = vm.candidates[0].id

        vm.toggleSelection(id)

        XCTAssertFalse(vm.candidates[0].isSelected)
        XCTAssertEqual(vm.selectedCount, 1)
    }

    @MainActor
    func test_deselectAll_deselectsAllCandidates() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()

        vm.deselectAll()

        XCTAssertEqual(vm.selectedCount, 0)
    }

    @MainActor
    func test_selectAll_selectsAllCandidates() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        vm.deselectAll()

        vm.selectAll()

        XCTAssertEqual(vm.selectedCount, 2)
    }

    // MARK: - Free Tier

    @MainActor
    func test_codesOverFreeLimit_proUser_alwaysZero() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        XCTAssertEqual(vm.codesOverFreeLimit(currentCodeCount: 14, isProUnlocked: true), 0)
    }

    @MainActor
    func test_codesOverFreeLimit_freeUser_underLimit_zero() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        XCTAssertEqual(vm.codesOverFreeLimit(currentCodeCount: 10, isProUnlocked: false), 0)
    }

    @MainActor
    func test_codesOverFreeLimit_freeUser_overLimit_returnsOverflow() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        XCTAssertEqual(vm.codesOverFreeLimit(currentCodeCount: 14, isProUnlocked: false), 1)
    }

    @MainActor
    func test_codesOverFreeLimit_freeUser_atLimit_returnsAllSelected() {
        let vm = PDFImportViewModel()
        vm.candidates = makeCandidates()
        XCTAssertEqual(vm.codesOverFreeLimit(currentCodeCount: 15, isProUnlocked: false), 2)
    }
}
