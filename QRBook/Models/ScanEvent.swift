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
