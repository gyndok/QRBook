import Foundation

enum QRDataDecoder {

    /// Normalizes CRLF / lone CR line endings (used by RFC-compliant external
    /// generators) to LF, then splits into lines.
    private static func normalizedLines(from data: String) -> [String] {
        data
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    static func decodeWiFi(from data: String) -> WiFiData? {
        guard data.hasPrefix("WIFI:") else { return nil }
        var ssid = "", password = ""
        var hidden = false
        var security: WiFiData.Security = .WPA

        let content = String(data.dropFirst(5))
        let parts = QRFieldEscaping.splitUnescaped(content, on: ";")
        for part in parts {
            if part.hasPrefix("T:") {
                let val = String(part.dropFirst(2))
                security = WiFiData.Security(rawValue: val) ?? .WPA
            } else if part.hasPrefix("S:") {
                ssid = QRFieldEscaping.unescapeWiFi(String(part.dropFirst(2)))
            } else if part.hasPrefix("P:") {
                password = QRFieldEscaping.unescapeWiFi(String(part.dropFirst(2)))
            } else if part.hasPrefix("H:") {
                hidden = String(part.dropFirst(2)).lowercased() == "true"
            }
        }
        return WiFiData(ssid: ssid, password: password, security: security, hidden: hidden)
    }

    static func decodeContact(from data: String) -> ContactData? {
        guard data.contains("BEGIN:VCARD") else { return nil }
        var contact = ContactData()
        for line in normalizedLines(from: data) {
            if line.hasPrefix("FN:") {
                contact.name = QRFieldEscaping.unescapeText(String(line.dropFirst(3)))
            } else if line.hasPrefix("TEL") {
                if let colonIdx = line.firstIndex(of: ":") {
                    contact.phone = String(line[line.index(after: colonIdx)...])
                }
            } else if line.hasPrefix("EMAIL:") {
                contact.email = String(line.dropFirst(6))
            } else if line.hasPrefix("ORG:") {
                contact.organization = QRFieldEscaping.unescapeText(String(line.dropFirst(4)))
            } else if line.hasPrefix("URL:") {
                contact.url = String(line.dropFirst(4))
            }
        }
        return contact
    }

    static func decodeCalendarEvent(from data: String) -> CalendarEventData? {
        guard data.contains("BEGIN:VEVENT") else { return nil }
        var event = CalendarEventData()

        for line in normalizedLines(from: data) {
            if line.hasPrefix("SUMMARY:") {
                event.title = QRFieldEscaping.unescapeText(String(line.dropFirst(8)))
            } else if line.hasPrefix("LOCATION:") {
                event.location = QRFieldEscaping.unescapeText(String(line.dropFirst(9)))
            } else if line.hasPrefix("DESCRIPTION:") {
                event.eventDescription = QRFieldEscaping.unescapeText(String(line.dropFirst(12)))
            } else if line.hasPrefix("DTSTART;VALUE=DATE:") {
                event.allDay = true
                if let d = QRDataEncoder.icalDateFormatter("yyyyMMdd").date(from: String(line.dropFirst(19))) {
                    event.startDate = d
                }
            } else if line.hasPrefix("DTEND;VALUE=DATE:") {
                if let d = QRDataEncoder.icalDateFormatter("yyyyMMdd").date(from: String(line.dropFirst(17))) {
                    event.endDate = d
                }
            } else if line.hasPrefix("DTSTART:") {
                if let d = parseICalDateTime(String(line.dropFirst(8))) {
                    event.startDate = d
                    event.startTime = d
                }
            } else if line.hasPrefix("DTEND:") {
                if let d = parseICalDateTime(String(line.dropFirst(6))) {
                    event.endDate = d
                    event.endTime = d
                }
            }
        }
        return event
    }

    /// Parses an iCal date-time value in either local (`yyyyMMdd'T'HHmmss`)
    /// or UTC (`...Z`) form.
    private static func parseICalDateTime(_ value: String) -> Date? {
        if value.hasSuffix("Z") {
            return QRDataEncoder.icalDateFormatter("yyyyMMdd'T'HHmmss'Z'", utc: true).date(from: value)
        }
        return QRDataEncoder.icalDateFormatter("yyyyMMdd'T'HHmmss").date(from: value)
    }

    static func decodePayment(from data: String, type: QRType) -> String {
        switch type {
        case .venmo:
            return data.replacingOccurrences(of: "https://venmo.com/", with: "")
        case .paypal:
            return data.replacingOccurrences(of: "https://www.paypal.com/paypalme/", with: "")
        case .cashapp:
            return data.replacingOccurrences(of: "https://cash.app/$", with: "")
        case .zelle:
            return data.replacingOccurrences(of: "Zelle: ", with: "")
        default:
            return data
        }
    }
}
