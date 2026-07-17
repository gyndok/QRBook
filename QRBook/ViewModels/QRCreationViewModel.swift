import SwiftUI
import UIKit

@Observable
class QRCreationViewModel {
    var selectedType: QRType = .url
    var title = ""
    var data = ""
    var tags: [String] = []
    var newTag = ""
    var isFavorite = false
    var errorCorrection: ErrorCorrectionLevel = .M
    var sizePx = 512
    var oneTimeUse = false
    var brightnessBoostDefault = true
    var showAdvanced = false
    var foregroundHex = ""
    var backgroundHex = ""
    var foregroundColor: Color = .black
    var backgroundColor: Color = .white
    var logoImageData: Data?
    var folderName = ""

    // Type-specific data
    var wifiData = WiFiData(ssid: "", password: "", security: .WPA)
    var contactData = ContactData()
    var calendarData = CalendarEventData()

    var validationError: String?

    /// Seeds creation defaults from the Settings screen's "Default Settings"
    /// section; without this those settings have no effect.
    init(defaults: UserDefaults = .standard) {
        if defaults.object(forKey: "defaultSize") != nil {
            sizePx = defaults.integer(forKey: "defaultSize")
        }
        if let level = defaults.string(forKey: "defaultErrorCorrection")
            .flatMap(ErrorCorrectionLevel.init(rawValue:)) {
            errorCorrection = level
        }
        if defaults.object(forKey: "defaultBrightnessBoost") != nil {
            brightnessBoostDefault = defaults.bool(forKey: "defaultBrightnessBoost")
        }
        isFavorite = defaults.bool(forKey: "defaultAutoFavorite")
    }

    func validate() -> Bool {
        if let error = Validation.validateTitle(title) {
            validationError = error
            return false
        }

        switch selectedType {
        case .url, .file:
            if let error = Validation.validateURL(data) {
                validationError = error
                return false
            }
        case .text:
            if let error = Validation.validateText(data) {
                validationError = error
                return false
            }
        case .wifi:
            if let error = Validation.validateRequired(wifiData.ssid, fieldName: "Network name") {
                validationError = error
                return false
            }
        case .contact:
            if let error = Validation.validateRequired(contactData.name, fieldName: "Contact name") {
                validationError = error
                return false
            }
        case .calendar:
            if let error = Validation.validateRequired(calendarData.title, fieldName: "Event title") {
                validationError = error
                return false
            }
        case .venmo, .paypal, .cashapp, .zelle, .crypto:
            if let error = Validation.validateRequired(data, fieldName: selectedType.label) {
                validationError = error
                return false
            }
        }

        validationError = nil
        return true
    }

    func generateQRData() -> String {
        switch selectedType {
        case .url, .file: return Validation.normalizeURL(data)
        case .wifi: return QRDataEncoder.encodeWiFi(wifiData)
        case .contact: return QRDataEncoder.encodeContact(contactData)
        case .calendar: return QRDataEncoder.encodeCalendarEvent(calendarData)
        case .venmo: return QRDataEncoder.encodeVenmo(data)
        case .paypal: return QRDataEncoder.encodePayPal(data)
        case .cashapp: return QRDataEncoder.encodeCashApp(data)
        case .zelle: return QRDataEncoder.encodeZelle(data)
        default: return data
        }
    }

    func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Validation.validateTag(trimmed) == nil,
              !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    /// Stores a logo image, downscaled so large photos don't bloat the
    /// SwiftData store (and CloudKit sync payloads). The logo overlay obscures
    /// the QR center, so error correction is raised to High to keep the code
    /// scannable.
    func setLogo(fromImageData data: Data) {
        guard let image = UIImage(data: data) else { return }

        let maxDimension: CGFloat = 512
        let largest = max(image.size.width, image.size.height)
        if largest > maxDimension {
            let scale = maxDimension / largest
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            logoImageData = resized.pngData()
        } else {
            logoImageData = data
        }

        errorCorrection = .H
    }

    func removeLogo() {
        logoImageData = nil
    }

    func syncColors() {
        foregroundHex = Self.hexString(from: UIColor(foregroundColor)) ?? "000000"
        backgroundHex = Self.hexString(from: UIColor(backgroundColor)) ?? "FFFFFF"
    }

    /// getRed converts grayscale/extended colorspaces to RGB; clamping guards
    /// against extended-sRGB components outside 0...1.
    private static func hexString(from color: UIColor) -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        func channel(_ value: CGFloat) -> Int {
            Int((min(max(value, 0), 1) * 255).rounded())
        }
        return String(format: "%02X%02X%02X", channel(r), channel(g), channel(b))
    }
}
