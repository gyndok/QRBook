import Foundation

/// Auto-generated label for a detected QR code payload.
struct QRLabel {
    var suggestedTitle: String
    var suggestedTags: [String]
    var detectedType: QRType
}

enum QRAutoLabeler {

    /// Analyzes a QR payload and generates a suggested title, tags, and detected type.
    static func label(payload: String) -> QRLabel {
        let type = detectType(payload)
        let title = suggestTitle(payload: payload, type: type)
        let tags = suggestTags(payload: payload, type: type)
        return QRLabel(suggestedTitle: title, suggestedTags: tags, detectedType: type)
    }

    // MARK: - Type Detection

    static func detectType(_ payload: String) -> QRType {
        if payload.hasPrefix("WIFI:") { return .wifi }
        if payload.contains("BEGIN:VCARD") { return .contact }
        if payload.contains("BEGIN:VCALENDAR") || payload.contains("BEGIN:VEVENT") { return .calendar }
        if payload.hasPrefix("https://venmo.com/") { return .venmo }
        if payload.contains("paypal.com/paypalme/") || payload.contains("paypal.me/") { return .paypal }
        if payload.hasPrefix("https://cash.app/$") { return .cashapp }
        if payload.hasPrefix("Zelle: ") { return .zelle }
        if payload.hasPrefix("bitcoin:") || payload.hasPrefix("ethereum:") { return .crypto }
        if payload.hasPrefix("http://") || payload.hasPrefix("https://") { return .url }
        return .text
    }

    // MARK: - Title Suggestion

    private static func suggestTitle(payload: String, type: QRType) -> String {
        switch type {
        case .url:
            return titleFromURL(payload)
        case .wifi:
            if let wifi = QRDataDecoder.decodeWiFi(from: payload) {
                return "Wi-Fi: \(wifi.ssid)"
            }
            return "Wi-Fi Network"
        case .contact:
            if let contact = QRDataDecoder.decodeContact(from: payload) {
                return contact.name.isEmpty ? "Contact" : contact.name
            }
            return "Contact"
        case .calendar:
            if let event = QRDataDecoder.decodeCalendarEvent(from: payload) {
                return event.title.isEmpty ? "Calendar Event" : event.title
            }
            return "Calendar Event"
        case .venmo:
            let username = QRDataDecoder.decodePayment(from: payload, type: .venmo)
            return username.isEmpty ? "Venmo" : "Venmo: \(username)"
        case .paypal:
            let username = QRDataDecoder.decodePayment(from: payload, type: .paypal)
            return username.isEmpty ? "PayPal" : "PayPal: \(username)"
        case .cashapp:
            let username = QRDataDecoder.decodePayment(from: payload, type: .cashapp)
            return username.isEmpty ? "Cash App" : "Cash App: \(username)"
        case .zelle:
            let contact = QRDataDecoder.decodePayment(from: payload, type: .zelle)
            return contact.isEmpty ? "Zelle" : "Zelle: \(contact)"
        case .crypto:
            return "Crypto Wallet"
        case .text:
            let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count <= 40 {
                return trimmed
            }
            return String(trimmed.prefix(37)) + "..."
        case .file:
            return titleFromURL(payload)
        }
    }

    private static func titleFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return "Link"
        }
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return domain
    }

    // MARK: - Tag Suggestion

    private static func suggestTags(payload: String, type: QRType) -> [String] {
        switch type {
        case .url:
            return tagsByURLDomain(payload)
        case .wifi:
            return ["wifi"]
        case .contact:
            return ["contact"]
        case .calendar:
            return ["event"]
        case .venmo, .paypal, .cashapp, .zelle:
            return ["payment"]
        case .crypto:
            return ["crypto"]
        case .text, .file:
            return []
        }
    }

    private static func tagsByURLDomain(_ urlString: String) -> [String] {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return []
        }

        let travelDomains = ["united.com", "delta.com", "aa.com", "southwest.com",
                             "jetblue.com", "spirit.com", "alaskaair.com",
                             "booking.com", "airbnb.com", "expedia.com",
                             "marriott.com", "hilton.com", "hyatt.com"]
        if travelDomains.contains(where: { host.contains($0) }) {
            return ["travel"]
        }

        let ticketDomains = ["ticketmaster.com", "stubhub.com", "eventbrite.com",
                             "axs.com", "seatgeek.com", "dice.fm"]
        if ticketDomains.contains(where: { host.contains($0) }) {
            return ["tickets"]
        }

        return []
    }
}
