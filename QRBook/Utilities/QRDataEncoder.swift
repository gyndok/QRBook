import Foundation

// MARK: - Data Types

struct WiFiData {
    var ssid: String
    var password: String
    var security: Security
    var hidden: Bool = false

    enum Security: String, CaseIterable, Identifiable {
        case WPA, WEP, nopass
        var id: String { rawValue }
        var label: String {
            switch self {
            case .WPA: "WPA/WPA2"
            case .WEP: "WEP"
            case .nopass: "No Password"
            }
        }
    }
}

struct ContactData {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var organization: String = ""
    var url: String = ""
}

struct CalendarEventData {
    var title: String = ""
    var startDate: Date = .now
    var endDate: Date = .now
    var startTime: Date = .now
    var endTime: Date = .now
    var location: String = ""
    var eventDescription: String = ""
    var allDay: Bool = false
}

// MARK: - Field Escaping

/// Escaping rules shared by the WIFI: format (backslash before \ ; , : ")
/// and vCard/iCalendar TEXT values (backslash before \ ; , and \n for newlines).
enum QRFieldEscaping {

    static func escapeWiFi(_ value: String) -> String {
        var out = ""
        for ch in value {
            if "\\;,:\"".contains(ch) { out.append("\\") }
            out.append(ch)
        }
        return out
    }

    static func escapeText(_ value: String) -> String {
        var out = ""
        for ch in value {
            switch ch {
            case "\\", ";", ",":
                out.append("\\")
                out.append(ch)
            case "\n":
                out.append("\\n")
            default:
                out.append(ch)
            }
        }
        return out
    }

    static func unescapeWiFi(_ value: String) -> String {
        var out = ""
        var escaped = false
        for ch in value {
            if escaped {
                out.append(ch)
                escaped = false
            } else if ch == "\\" {
                escaped = true
            } else {
                out.append(ch)
            }
        }
        return out
    }

    static func unescapeText(_ value: String) -> String {
        var out = ""
        var escaped = false
        for ch in value {
            if escaped {
                out.append(ch == "n" || ch == "N" ? "\n" : String(ch))
                escaped = false
            } else if ch == "\\" {
                escaped = true
            } else {
                out.append(ch)
            }
        }
        return out
    }

    /// Splits on `separator`, ignoring separators preceded by a backslash.
    /// Escape sequences are preserved in the returned parts.
    static func splitUnescaped(_ value: String, on separator: Character) -> [String] {
        var parts: [String] = []
        var current = ""
        var escaped = false
        for ch in value {
            if escaped {
                current.append(ch)
                escaped = false
            } else if ch == "\\" {
                current.append(ch)
                escaped = true
            } else if ch == separator {
                parts.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        parts.append(current)
        return parts
    }
}

// MARK: - QR Data Encoder

enum QRDataEncoder {

    /// Fixed-format iCal dates must use en_US_POSIX so a user's 12/24-hour
    /// override can't rewrite HH patterns (Apple QA1480).
    static func icalDateFormatter(_ format: String, utc: Bool = false) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if utc { formatter.timeZone = TimeZone(identifier: "UTC") }
        formatter.dateFormat = format
        return formatter
    }

    // MARK: - WiFi

    static func encodeWiFi(_ wifi: WiFiData) -> String {
        let hidden = wifi.hidden ? "true" : "false"
        let ssid = QRFieldEscaping.escapeWiFi(wifi.ssid)
        let password = QRFieldEscaping.escapeWiFi(wifi.password)
        return "WIFI:T:\(wifi.security.rawValue);S:\(ssid);P:\(password);H:\(hidden);;"
    }

    // MARK: - Contact (vCard 3.0)

    static func encodeContact(_ contact: ContactData) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCARD")
        lines.append("VERSION:3.0")

        if !contact.name.isEmpty {
            lines.append("FN:\(QRFieldEscaping.escapeText(contact.name))")
            // Attempt a simple LAST;FIRST split on space
            let parts = contact.name.split(separator: " ", maxSplits: 1)
            if parts.count == 2 {
                let last = QRFieldEscaping.escapeText(String(parts[1]))
                let first = QRFieldEscaping.escapeText(String(parts[0]))
                lines.append("N:\(last);\(first);;;")
            } else {
                lines.append("N:\(QRFieldEscaping.escapeText(contact.name));;;;")
            }
        }

        if !contact.phone.isEmpty {
            lines.append("TEL;TYPE=CELL:\(contact.phone)")
        }

        if !contact.email.isEmpty {
            lines.append("EMAIL:\(contact.email)")
        }

        if !contact.organization.isEmpty {
            lines.append("ORG:\(QRFieldEscaping.escapeText(contact.organization))")
        }

        if !contact.url.isEmpty {
            lines.append("URL:\(contact.url)")
        }

        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }

    // MARK: - Calendar Event (iCalendar)

    static func encodeCalendarEvent(_ event: CalendarEventData) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("BEGIN:VEVENT")

        if event.allDay {
            // All-day events use DATE format (yyyyMMdd)
            let formatter = icalDateFormatter("yyyyMMdd")
            let startStr = formatter.string(from: event.startDate)
            let endStr = formatter.string(from: event.endDate)
            lines.append("DTSTART;VALUE=DATE:\(startStr)")
            lines.append("DTEND;VALUE=DATE:\(endStr)")
        } else {
            // Timed events: combine date portion from startDate/endDate with time from startTime/endTime
            let calendar = Calendar.current

            let startDateComponents = calendar.dateComponents([.year, .month, .day], from: event.startDate)
            let startTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: event.startTime)
            var startCombined = DateComponents()
            startCombined.year = startDateComponents.year
            startCombined.month = startDateComponents.month
            startCombined.day = startDateComponents.day
            startCombined.hour = startTimeComponents.hour
            startCombined.minute = startTimeComponents.minute
            startCombined.second = startTimeComponents.second

            let endDateComponents = calendar.dateComponents([.year, .month, .day], from: event.endDate)
            let endTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: event.endTime)
            var endCombined = DateComponents()
            endCombined.year = endDateComponents.year
            endCombined.month = endDateComponents.month
            endCombined.day = endDateComponents.day
            endCombined.hour = endTimeComponents.hour
            endCombined.minute = endTimeComponents.minute
            endCombined.second = endTimeComponents.second

            let formatter = icalDateFormatter("yyyyMMdd'T'HHmmss")
            if let start = calendar.date(from: startCombined) {
                lines.append("DTSTART:\(formatter.string(from: start))")
            }
            if let end = calendar.date(from: endCombined) {
                lines.append("DTEND:\(formatter.string(from: end))")
            }
        }

        if !event.title.isEmpty {
            lines.append("SUMMARY:\(QRFieldEscaping.escapeText(event.title))")
        }

        if !event.location.isEmpty {
            lines.append("LOCATION:\(QRFieldEscaping.escapeText(event.location))")
        }

        if !event.eventDescription.isEmpty {
            lines.append("DESCRIPTION:\(QRFieldEscaping.escapeText(event.eventDescription))")
        }

        lines.append("END:VEVENT")
        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\n")
    }

    // MARK: - Payment Encoders

    static func encodeVenmo(_ username: String) -> String {
        let clean = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        return "https://venmo.com/\(clean)"
    }

    static func encodePayPal(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // If the input looks like an email, build a paypal.me mailto-style link
        if trimmed.contains("@") {
            return "https://www.paypal.com/paypalme/\(trimmed)"
        }
        // Otherwise treat it as a PayPal.me username
        let clean = trimmed
            .replacingOccurrences(of: "@", with: "")
        return "https://www.paypal.com/paypalme/\(clean)"
    }

    static func encodeCashApp(_ cashtag: String) -> String {
        let clean = cashtag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
        return "https://cash.app/$\(clean)"
    }

    static func encodeZelle(_ contact: String) -> String {
        let trimmed = contact.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Zelle: \(trimmed)"
    }
}
