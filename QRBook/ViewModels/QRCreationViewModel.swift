import SwiftUI

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
}
