import AppIntents
import SwiftData

struct ShowQRCodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Show QR Code"
    static var description = IntentDescription("Opens a QR code in fullscreen view")
    static var openAppWhenRun = true

    @Parameter(title: "QR Code")
    var qrCode: QRCodeEntity

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct QRCodeEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "QR Code")
    static var defaultQuery = QRCodeEntityQuery()

    var id: UUID
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct QRCodeEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [QRCodeEntity] {
        return []
    }

    func suggestedEntities() async throws -> [QRCodeEntity] {
        return []
    }
}
