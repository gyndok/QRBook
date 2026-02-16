import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "folder.fill"
    var colorHex: String = "7C3AED"
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "folder.fill",
        colorHex: String = "7C3AED",
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
