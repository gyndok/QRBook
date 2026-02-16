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

// MARK: - QR Data Encoder

enum QRDataEncoder {

    // MARK: - WiFi

    static func encodeWiFi(_ wifi: WiFiData) -> String {
        let hidden = wifi.hidden ? "true" : "false"
        return "WIFI:T:\(wifi.security.rawValue);S:\(wifi.ssid);P:\(wifi.password);H:\(hidden);;"
    }

    // MARK: - Contact (vCard 3.0)

    static func encodeContact(_ contact: ContactData) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCARD")
        lines.append("VERSION:3.0")

        if !contact.name.isEmpty {
            lines.append("FN:\(contact.name)")
            // Attempt a simple LAST;FIRST split on space
            let parts = contact.name.split(separator: " ", maxSplits: 1)
            if parts.count == 2 {
                lines.append("N:\(parts[1]);\(parts[0]);;;")
            } else {
                lines.append("N:\(contact.name);;;;")
            }
        }

        if !contact.phone.isEmpty {
            lines.append("TEL;TYPE=CELL:\(contact.phone)")
        }

        if !contact.email.isEmpty {
            lines.append("EMAIL:\(contact.email)")
        }

        if !contact.organization.isEmpty {
            lines.append("ORG:\(contact.organization)")
        }

        if !contact.url.isEmpty {
            lines.append("URL:\(contact.url)")
        }

        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }

    // MARK: - Calendar Event (iCalendar)

    static func encodeCalendarEvent(_ event: CalendarEventData) -> String {
        let formatter = DateFormatter()

        var lines: [String] = []
        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("BEGIN:VEVENT")

        if event.allDay {
            // All-day events use DATE format (yyyyMMdd)
            formatter.dateFormat = "yyyyMMdd"
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

            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            if let start = calendar.date(from: startCombined) {
                lines.append("DTSTART:\(formatter.string(from: start))")
            }
            if let end = calendar.date(from: endCombined) {
                lines.append("DTEND:\(formatter.string(from: end))")
            }
        }

        if !event.title.isEmpty {
            lines.append("SUMMARY:\(event.title)")
        }

        if !event.location.isEmpty {
            lines.append("LOCATION:\(event.location)")
        }

        if !event.eventDescription.isEmpty {
            lines.append("DESCRIPTION:\(event.eventDescription)")
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
