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

    func syncColors() {
        let fgComponents = UIColor(foregroundColor).cgColor.components ?? [0, 0, 0]
        foregroundHex = String(format: "%02X%02X%02X",
            Int((fgComponents.count > 0 ? fgComponents[0] : 0) * 255),
            Int((fgComponents.count > 1 ? fgComponents[1] : 0) * 255),
            Int((fgComponents.count > 2 ? fgComponents[2] : 0) * 255))

        let bgComponents = UIColor(backgroundColor).cgColor.components ?? [1, 1, 1]
        backgroundHex = String(format: "%02X%02X%02X",
            Int((bgComponents.count > 0 ? bgComponents[0] : 0) * 255),
            Int((bgComponents.count > 1 ? bgComponents[1] : 0) * 255),
            Int((bgComponents.count > 2 ? bgComponents[2] : 0) * 255))
    }
}
