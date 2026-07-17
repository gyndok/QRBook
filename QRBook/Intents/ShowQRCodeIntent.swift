import AppIntents
import Foundation

struct ShowQRCodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Show QR Code"
    static var description = IntentDescription("Opens a QR code in fullscreen view")
    static var openAppWhenRun = true

    @Parameter(title: "QR Code")
    var qrCode: QRCodeEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkRouter.shared.showQRCode(id: qrCode.id)
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
        loadFavorites().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [QRCodeEntity] {
        loadFavorites()
    }

    /// Favorites exported to the app-group container for the widget double as
    /// the Siri/Shortcuts entity source, so no SwiftData access is needed here.
    private func loadFavorites() -> [QRCodeEntity] {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        )?.appendingPathComponent("widget-data.json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }

        return items.compactMap { item in
            guard let idString = item["id"],
                  let id = UUID(uuidString: idString),
                  let title = item["title"] else { return nil }
            return QRCodeEntity(id: id, title: title)
        }
    }
}
