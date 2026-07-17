import Foundation
import SwiftData

/// Represents one detected QR code with editable metadata for the import preview.
@Observable
class ImportCandidate: Identifiable {
    let id: UUID
    let payload: String
    let symbology: String
    let pageNumbers: [Int]
    var title: String
    var tags: [String]
    var detectedType: QRType
    var isSelected: Bool

    init(from detected: DetectedQRCode, label: QRLabel) {
        self.id = detected.id
        self.payload = detected.payload
        self.symbology = detected.symbology.rawValue
        self.pageNumbers = detected.pageNumbers
        self.title = label.suggestedTitle
        self.tags = label.suggestedTags
        self.detectedType = label.detectedType
        self.isSelected = true
    }
}

enum ImportState: Equatable {
    case idle
    case scanning(currentPage: Int, totalPages: Int)
    case results
    case empty
    case error(String)
    case saved(Int)

    static func == (lhs: ImportState, rhs: ImportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.results, .results), (.empty, .empty):
            return true
        case (.scanning(let lc, let lt), .scanning(let rc, let rt)):
            return lc == rc && lt == rt
        case (.error(let l), .error(let r)):
            return l == r
        case (.saved(let l), .saved(let r)):
            return l == r
        default:
            return false
        }
    }
}

@MainActor @Observable
class PDFImportViewModel {

    var state: ImportState = .idle
    var candidates: [ImportCandidate] = []
    var pdfFilename: String = ""

    var selectedCount: Int {
        candidates.filter(\.isSelected).count
    }

    // MARK: - Scanning

    func scanPDF(url: URL) async {
        pdfFilename = url.lastPathComponent

        do {
            state = .scanning(currentPage: 0, totalPages: 0)

            let detected = try await PDFQRScanner.scanPDF(url: url) { [weak self] current, total in
                Task { @MainActor [weak self] in
                    self?.state = .scanning(currentPage: current, totalPages: total)
                }
            }

            if detected.isEmpty {
                candidates = []
                state = .empty
            } else {
                candidates = detected.map { code in
                    let label = QRAutoLabeler.label(payload: code.payload)
                    return ImportCandidate(from: code, label: label)
                }
                state = .results
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Selection

    func toggleSelection(_ id: UUID) {
        if let candidate = candidates.first(where: { $0.id == id }) {
            candidate.isSelected.toggle()
        }
    }

    func selectAll() {
        candidates.forEach { $0.isSelected = true }
    }

    func deselectAll() {
        candidates.forEach { $0.isSelected = false }
    }

    // MARK: - Save

    func codesOverFreeLimit(currentCodeCount: Int, isProUnlocked: Bool) -> Int {
        guard !isProUnlocked else { return 0 }
        let remaining = max(0, StoreManager.freeCodeLimit - currentCodeCount)
        let overflow = selectedCount - remaining
        return max(0, overflow)
    }

    func saveSelected(to context: ModelContext) -> Int {
        let selected = candidates.filter(\.isSelected)

        for candidate in selected {
            let qrCode = QRCode(
                title: candidate.title,
                data: candidate.payload,
                type: candidate.detectedType,
                tags: candidate.tags
            )
            context.insert(qrCode)
            SpotlightIndexer.indexQRCode(qrCode)
        }

        let count = selected.count
        state = .saved(count)
        return count
    }

    // MARK: - Reset

    func reset() {
        state = .idle
        candidates = []
        pdfFilename = ""
    }
}
