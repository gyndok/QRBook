import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case lastUsed = "Recent"
    case newest = "Newest"
    case nameAZ = "Name A-Z"
    case mostUsed = "Most Used"

    var id: String { rawValue }
}

@Observable
class QRLibraryViewModel {
    var searchText = ""
    var sortOption: SortOption = .lastUsed
    var filterType: QRType? = nil
    var filterFavoritesOnly = false
    var filterTags: Set<String> = []
    var showFilterSheet = false
    var showCreateSheet = false
    var filterFolder: String? = nil

    func filteredAndSorted(_ qrCodes: [QRCode], viewMode: ViewMode) -> [QRCode] {
        var result = qrCodes

        // Apply view mode
        switch viewMode {
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .recent:
            result = result.sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            result = Array(result.prefix(10))
            return result
        case .all:
            break
        }

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.data.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }

        // Type filter
        if let filterType {
            result = result.filter { $0.type == filterType }
        }

        // Favorites filter
        if filterFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // Tag filter
        if !filterTags.isEmpty {
            result = result.filter { qr in
                filterTags.allSatisfy { qr.tags.contains($0) }
            }
        }

        // Folder filter
        if let filterFolder {
            result = result.filter { $0.folderName == filterFolder }
        }

        // Sort
        switch sortOption {
        case .lastUsed:
            result.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .nameAZ:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .mostUsed:
            result.sort { $0.scanCount > $1.scanCount }
        }

        return result
    }

    var activeFilterCount: Int {
        var count = 0
        if filterType != nil { count += 1 }
        if filterFavoritesOnly { count += 1 }
        if !filterTags.isEmpty { count += 1 }
        if filterFolder != nil { count += 1 }
        return count
    }

    func clearFilters() {
        searchText = ""
        filterType = nil
        filterFavoritesOnly = false
        filterTags = []
        filterFolder = nil
    }

    func allTags(from qrCodes: [QRCode]) -> [String] {
        let tagSet = Set(qrCodes.flatMap { $0.tags })
        return tagSet.sorted()
    }
}
