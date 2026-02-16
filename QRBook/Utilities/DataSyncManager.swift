import Foundation
import SwiftData

enum DataSyncManager {
    static func syncFavorites(context: ModelContext) {
        let descriptor = FetchDescriptor<QRCode>(predicate: #Predicate { $0.isFavorite })
        guard let favorites = try? context.fetch(descriptor) else { return }
        WidgetDataWriter.writeWidgetData(favorites: favorites)
        WatchConnector.shared.sendFavorites(favorites)
    }
}
