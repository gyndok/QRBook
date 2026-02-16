import Foundation
import WidgetKit

enum WidgetDataWriter {
    static func writeWidgetData(favorites: [QRCode]) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else { return }

        let items = favorites.map { qr -> [String: String] in
            [
                "id": qr.id.uuidString,
                "title": qr.title,
                "data": qr.data,
                "type": qr.typeRaw,
                "foregroundHex": qr.foregroundHex,
                "backgroundHex": qr.backgroundHex
            ]
        }

        let url = containerURL.appendingPathComponent("widget-data.json")
        if let jsonData = try? JSONSerialization.data(withJSONObject: items) {
            try? jsonData.write(to: url)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
