import Foundation
import SwiftData

@Model
final class ScanEvent {
    var id: UUID = UUID()
    var qrCodeId: UUID = UUID()
    var timestamp: Date = Date()

    init(
        id: UUID = UUID(),
        qrCodeId: UUID,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.qrCodeId = qrCodeId
        self.timestamp = timestamp
    }
}

extension ScanEvent {
    /// Cap on retained scan events per QR code. Scan history is local-only
    /// telemetry, so this bounds on-device growth without touching CloudKit.
    static let maxHistoryPerCode = 100

    /// Records a scan and trims this code's history to the most recent
    /// `limit` events.
    static func record(qrCodeId: UUID, in context: ModelContext, keeping limit: Int = maxHistoryPerCode) {
        context.insert(ScanEvent(qrCodeId: qrCodeId))
        prune(qrCodeId: qrCodeId, in: context, keeping: limit)
    }

    static func prune(qrCodeId: UUID, in context: ModelContext, keeping limit: Int = maxHistoryPerCode) {
        let descriptor = FetchDescriptor<ScanEvent>(
            predicate: #Predicate { $0.qrCodeId == qrCodeId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let events = try? context.fetch(descriptor), events.count > limit else { return }
        for event in events[limit...] {
            context.delete(event)
        }
    }
}
