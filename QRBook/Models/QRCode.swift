import Foundation
import SwiftData

// MARK: - QRType Enum

enum QRType: String, CaseIterable, Identifiable, Codable {
    case url
    case text
    case wifi
    case contact
    case file
    case venmo
    case paypal
    case cashapp
    case zelle
    case crypto
    case calendar

    var id: String { rawValue }

    var label: String {
        switch self {
        case .url:      return "URL"
        case .text:     return "Text"
        case .wifi:     return "Wi-Fi"
        case .contact:  return "Contact"
        case .file:     return "File"
        case .venmo:    return "Venmo"
        case .paypal:   return "PayPal"
        case .cashapp:  return "Cash App"
        case .zelle:    return "Zelle"
        case .crypto:   return "Crypto"
        case .calendar: return "Calendar"
        }
    }

    var icon: String {
        switch self {
        case .url:      return "link"
        case .text:     return "doc.text"
        case .wifi:     return "wifi"
        case .contact:  return "person.crop.circle"
        case .file:     return "doc"
        case .venmo:    return "dollarsign.circle"
        case .paypal:   return "creditcard"
        case .cashapp:  return "banknote"
        case .zelle:    return "arrow.left.arrow.right"
        case .crypto:   return "bitcoinsign.circle"
        case .calendar: return "calendar"
        }
    }

    var description: String {
        switch self {
        case .url:      return "Link to a website or web resource"
        case .text:     return "Plain text content"
        case .wifi:     return "Wi-Fi network credentials"
        case .contact:  return "Contact information (vCard)"
        case .file:     return "Link to a file or document"
        case .venmo:    return "Venmo payment link"
        case .paypal:   return "PayPal payment link"
        case .cashapp:  return "Cash App payment link"
        case .zelle:    return "Zelle payment information"
        case .crypto:   return "Cryptocurrency wallet address"
        case .calendar: return "Calendar event details"
        }
    }

    var isPro: Bool {
        switch self {
        case .url, .text: return false
        default: return true
        }
    }
}

// MARK: - ErrorCorrectionLevel Enum

enum ErrorCorrectionLevel: String, CaseIterable, Identifiable, Codable {
    case L
    case M
    case Q
    case H

    var id: String { rawValue }

    var label: String {
        switch self {
        case .L: return "Low (7%)"
        case .M: return "Medium (15%)"
        case .Q: return "Quartile (25%)"
        case .H: return "High (30%)"
        }
    }
}

// MARK: - QRCode Model

@Model
final class QRCode {

    // MARK: Stored Properties (all have defaults for CloudKit compatibility)

    var id: UUID = UUID()
    var title: String = ""
    var data: String = ""
    var typeRaw: String = QRType.url.rawValue
    var tagsRaw: String = ""
    var isFavorite: Bool = false
    var errorCorrectionRaw: String = ErrorCorrectionLevel.M.rawValue
    var sizePx: Int = 512
    var oneTimeUse: Bool = false
    var expiresAt: Date?
    var scanCount: Int = 0
    var brightnessBoostDefault: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastUsed: Date?
    var folderName: String = ""
    var foregroundHex: String = ""
    var backgroundHex: String = ""
    var logoImageData: Data?

    // MARK: Computed Properties

    var type: QRType {
        get { QRType(rawValue: typeRaw) ?? .text }
        set { typeRaw = newValue.rawValue }
    }

    var errorCorrection: ErrorCorrectionLevel {
        get { ErrorCorrectionLevel(rawValue: errorCorrectionRaw) ?? .M }
        set { errorCorrectionRaw = newValue.rawValue }
    }

    /// Tags stored as a comma-separated string for CloudKit compatibility.
    var tags: [String] {
        get {
            guard !tagsRaw.isEmpty else { return [] }
            return tagsRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            tagsRaw = newValue.joined(separator: ",")
        }
    }

    // MARK: Initializer

    init(
        id: UUID = UUID(),
        title: String,
        data: String,
        type: QRType = .url,
        tags: [String] = [],
        isFavorite: Bool = false,
        errorCorrection: ErrorCorrectionLevel = .M,
        sizePx: Int = 300,
        oneTimeUse: Bool = false,
        expiresAt: Date? = nil,
        scanCount: Int = 0,
        brightnessBoostDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastUsed: Date? = nil,
        folderName: String = "",
        foregroundHex: String = "",
        backgroundHex: String = "",
        logoImageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.data = data
        self.typeRaw = type.rawValue
        self.tagsRaw = tags.joined(separator: ",")
        self.isFavorite = isFavorite
        self.errorCorrectionRaw = errorCorrection.rawValue
        self.sizePx = sizePx
        self.oneTimeUse = oneTimeUse
        self.expiresAt = expiresAt
        self.scanCount = scanCount
        self.brightnessBoostDefault = brightnessBoostDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsed = lastUsed
        self.folderName = folderName
        self.foregroundHex = foregroundHex
        self.backgroundHex = backgroundHex
        self.logoImageData = logoImageData
    }
}
