import CoreSpotlight
import UIKit

enum SpotlightIndexer {
    static func indexQRCode(_ qr: QRCode) {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = qr.title
        attributes.contentDescription = "\(qr.type.label) QR Code: \(qr.data.prefix(100))"
        attributes.keywords = qr.tags + [qr.type.label]

        if let image = QRGenerator.generateQRCode(from: qr.data, size: 120) {
            attributes.thumbnailData = image.pngData()
        }

        let item = CSSearchableItem(
            uniqueIdentifier: qr.id.uuidString,
            domainIdentifier: "com.gyndok.QRBook.qrcodes",
            attributeSet: attributes
        )
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    static func removeQRCode(id: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id.uuidString])
    }

    static func reindexAll(_ codes: [QRCode]) {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.gyndok.QRBook.qrcodes"]) { _ in
            let items = codes.map { qr -> CSSearchableItem in
                let attrs = CSSearchableItemAttributeSet(contentType: .text)
                attrs.title = qr.title
                attrs.contentDescription = "\(qr.type.label): \(qr.data.prefix(100))"
                attrs.keywords = qr.tags
                return CSSearchableItem(uniqueIdentifier: qr.id.uuidString, domainIdentifier: "com.gyndok.QRBook.qrcodes", attributeSet: attrs)
            }
            CSSearchableIndex.default().indexSearchableItems(items)
        }
    }
}
