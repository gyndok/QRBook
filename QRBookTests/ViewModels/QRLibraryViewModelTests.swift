import XCTest
@testable import QRBook

final class QRLibraryViewModelTests: XCTestCase {

    var vm: QRLibraryViewModel!

    override func setUp() {
        super.setUp()
        vm = QRLibraryViewModel()
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeSampleCodes() -> [QRCode] {
        let now = Date()
        return [
            TestData.makeQRCode(title: "Alpha", data: "https://alpha.com", type: .url, tags: ["work"], isFavorite: true, scanCount: 5, createdAt: now.addingTimeInterval(-300), lastUsed: now.addingTimeInterval(-60)),
            TestData.makeQRCode(title: "Beta", data: "https://beta.com", type: .text, tags: ["personal"], isFavorite: false, scanCount: 10, createdAt: now.addingTimeInterval(-200), lastUsed: now.addingTimeInterval(-120)),
            TestData.makeQRCode(title: "Gamma", data: "https://gamma.com", type: .wifi, tags: ["work", "personal"], isFavorite: true, scanCount: 1, createdAt: now.addingTimeInterval(-100), lastUsed: now.addingTimeInterval(-180), folderName: "Network"),
        ]
    }

    // MARK: - filteredAndSorted — view modes

    func test_filteredAndSorted_allMode_returnsAll() {
        let codes = makeSampleCodes()
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 3)
    }

    func test_filteredAndSorted_favoritesMode_filtersOnlyFavorites() {
        let codes = makeSampleCodes()
        let result = vm.filteredAndSorted(codes, viewMode: .favorites)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.isFavorite })
    }

    func test_filteredAndSorted_recentMode_returnsTop10SortedByLastUsed() {
        let codes = makeSampleCodes()
        let result = vm.filteredAndSorted(codes, viewMode: .recent)
        XCTAssertLessThanOrEqual(result.count, 10)
        XCTAssertEqual(result.first?.title, "Alpha") // most recently used
    }

    func test_filteredAndSorted_recentMode_limitsTo10() {
        var codes: [QRCode] = []
        for i in 0..<15 {
            codes.append(TestData.makeQRCode(title: "QR \(i)", lastUsed: Date().addingTimeInterval(Double(-i * 60))))
        }
        let result = vm.filteredAndSorted(codes, viewMode: .recent)
        XCTAssertEqual(result.count, 10)
    }

    // MARK: - filteredAndSorted — search

    func test_filteredAndSorted_searchText_matchesTitle() {
        let codes = makeSampleCodes()
        vm.searchText = "Alpha"
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Alpha")
    }

    func test_filteredAndSorted_searchText_matchesData() {
        let codes = makeSampleCodes()
        vm.searchText = "beta.com"
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Beta")
    }

    func test_filteredAndSorted_searchText_matchesTags() {
        let codes = makeSampleCodes()
        vm.searchText = "personal"
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 2)
    }

    func test_filteredAndSorted_searchText_caseInsensitive() {
        let codes = makeSampleCodes()
        vm.searchText = "ALPHA"
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - filteredAndSorted — filters

    func test_filteredAndSorted_filterType_filtersCorrectly() {
        let codes = makeSampleCodes()
        vm.filterType = .url
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.type, .url)
    }

    func test_filteredAndSorted_filterFavoritesOnly_filtersCorrectly() {
        let codes = makeSampleCodes()
        vm.filterFavoritesOnly = true
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertTrue(result.allSatisfy { $0.isFavorite })
    }

    func test_filteredAndSorted_filterTags_requiresAllTags() {
        let codes = makeSampleCodes()
        vm.filterTags = Set(["work", "personal"])
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Gamma")
    }

    func test_filteredAndSorted_filterFolder_filtersCorrectly() {
        let codes = makeSampleCodes()
        vm.filterFolder = "Network"
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.folderName, "Network")
    }

    func test_filteredAndSorted_multipleFilters_appliesAll() {
        let codes = makeSampleCodes()
        vm.filterType = .wifi
        vm.filterFavoritesOnly = true
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Gamma")
    }

    // MARK: - filteredAndSorted — sorting

    func test_filteredAndSorted_sortLastUsed_sortsCorrectly() {
        let codes = makeSampleCodes()
        vm.sortOption = .lastUsed
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.first?.title, "Alpha") // most recently used
    }

    func test_filteredAndSorted_sortNewest_sortsCorrectly() {
        let codes = makeSampleCodes()
        vm.sortOption = .newest
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.first?.title, "Gamma") // most recently created
    }

    func test_filteredAndSorted_sortNameAZ_sortsCorrectly() {
        let codes = makeSampleCodes()
        vm.sortOption = .nameAZ
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.map(\.title), ["Alpha", "Beta", "Gamma"])
    }

    func test_filteredAndSorted_sortMostUsed_sortsCorrectly() {
        let codes = makeSampleCodes()
        vm.sortOption = .mostUsed
        let result = vm.filteredAndSorted(codes, viewMode: .all)
        XCTAssertEqual(result.first?.title, "Beta") // scanCount: 10
    }

    // MARK: - Selection

    func test_toggleSelection_notSelected_addsToSet() {
        let id = UUID()
        vm.toggleSelection(id)
        XCTAssertTrue(vm.selectedIds.contains(id))
    }

    func test_toggleSelection_alreadySelected_removesFromSet() {
        let id = UUID()
        vm.selectedIds.insert(id)
        vm.toggleSelection(id)
        XCTAssertFalse(vm.selectedIds.contains(id))
    }

    func test_selectAll_multipleCodes_selectsAll() {
        let codes = makeSampleCodes()
        vm.selectAll(codes)
        XCTAssertEqual(vm.selectedIds.count, 3)
    }

    func test_deselectAll_clears() {
        vm.selectedIds = [UUID(), UUID()]
        vm.deselectAll()
        XCTAssertTrue(vm.selectedIds.isEmpty)
    }

    func test_exitSelectMode_resetsState() {
        vm.isSelectMode = true
        vm.selectedIds = [UUID()]
        vm.exitSelectMode()
        XCTAssertFalse(vm.isSelectMode)
        XCTAssertTrue(vm.selectedIds.isEmpty)
    }

    // MARK: - activeFilterCount

    func test_activeFilterCount_noFilters_returnsZero() {
        XCTAssertEqual(vm.activeFilterCount, 0)
    }

    func test_activeFilterCount_oneFilter_returnsOne() {
        vm.filterType = .url
        XCTAssertEqual(vm.activeFilterCount, 1)
    }

    func test_activeFilterCount_allFilters_countsAll() {
        vm.filterType = .url
        vm.filterFavoritesOnly = true
        vm.filterTags = ["tag"]
        vm.filterFolder = "Work"
        XCTAssertEqual(vm.activeFilterCount, 4)
    }

    // MARK: - clearFilters

    func test_clearFilters_resetsAllFilters() {
        vm.searchText = "search"
        vm.filterType = .url
        vm.filterFavoritesOnly = true
        vm.filterTags = ["tag"]
        vm.filterFolder = "Work"
        vm.clearFilters()
        XCTAssertEqual(vm.searchText, "")
        XCTAssertNil(vm.filterType)
        XCTAssertFalse(vm.filterFavoritesOnly)
        XCTAssertTrue(vm.filterTags.isEmpty)
        XCTAssertNil(vm.filterFolder)
    }

    // MARK: - allTags

    func test_allTags_emptyArray_returnsEmpty() {
        let result = vm.allTags(from: [])
        XCTAssertTrue(result.isEmpty)
    }

    func test_allTags_extractsUniqueSortedTags() {
        let codes = makeSampleCodes()
        let result = vm.allTags(from: codes)
        XCTAssertEqual(result, ["personal", "work"])
    }

    func test_allTags_handlesDuplicates() {
        let codes = [
            TestData.makeQRCode(tags: ["a", "b"]),
            TestData.makeQRCode(tags: ["b", "c"]),
        ]
        let result = vm.allTags(from: codes)
        XCTAssertEqual(result, ["a", "b", "c"])
    }
}
