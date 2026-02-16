import Foundation
import SwiftData

@Model
final class QRCode {
    var id: UUID
    var title: String
    var data: String
    var typeRaw: String
    var createdAt: Date

    init(title: String, data: String, type: String = "url") {
        self.id = UUID()
        self.title = title
        self.data = data
        self.typeRaw = type
        self.createdAt = Date()
    }
}
