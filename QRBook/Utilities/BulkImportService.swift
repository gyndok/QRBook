import Foundation
import SwiftData

// MARK: - Import Types

struct BulkImportFile: Decodable {
    let qr_codes: [BulkImportItem]
}

struct BulkImportItem: Decodable {
    // Required
    let title: String?
    let type: String?

    // Universal data field (url, text, file, payment, crypto)
    let data: String?

    // WiFi fields
    let wifi_ssid: String?
    let wifi_password: String?
    let wifi_security: String?
    let wifi_hidden: Bool?

    // Contact fields
    let contact_name: String?
    let contact_phone: String?
    let contact_email: String?
    let contact_organization: String?
    let contact_url: String?

    // Calendar fields
    let event_title: String?
    let event_start_date: String?
    let event_end_date: String?
    let event_start_time: String?
    let event_end_time: String?
    let event_location: String?
    let event_description: String?
    let event_all_day: Bool?

    // Optional metadata
    let tags: [String]?
    let is_favorite: Bool?
    let error_correction: String?
    let size: Int?
}

struct BulkImportResult {
    let successCount: Int
    let errors: [BulkImportError]
}

struct BulkImportError: Identifiable, Error {
    let id = UUID()
    let index: Int
    let title: String?
    let message: String
}

private struct ValidationError: Error {
    let message: String
}

// MARK: - Bulk Import Service

enum BulkImportService {

    // MARK: - Template Generation

    static func generateTemplate() -> String {
        let template: [String: Any] = [
            "_template_info": [
                "description": "QRBook Bulk Import Template — fill in the qr_codes array and import back into the app.",
                "instructions": [
                    "Each entry needs a 'title' (display name) and 'type' (see types below).",
                    "Most types just need a 'data' field with the content.",
                    "WiFi, Contact, and Calendar types use their own prefixed fields instead of 'data'.",
                    "Optional fields: 'tags' (array of strings), 'is_favorite' (true/false), 'error_correction' (L/M/Q/H), 'size' (256/512/1024).",
                    "Dates use YYYY-MM-DD format. Times use HH:MM 24-hour format."
                ],
                "types": [
                    [
                        "type": "url",
                        "required_fields": ["data"],
                        "example": ["title": "My Website", "type": "url", "data": "https://example.com"]
                    ],
                    [
                        "type": "text",
                        "required_fields": ["data"],
                        "example": ["title": "Welcome Message", "type": "text", "data": "Hello, scan this QR code!"]
                    ],
                    [
                        "type": "wifi",
                        "required_fields": ["wifi_ssid"],
                        "optional_fields": ["wifi_password", "wifi_security (WPA/WEP/nopass)", "wifi_hidden (true/false)"],
                        "example": ["title": "Office WiFi", "type": "wifi", "wifi_ssid": "MyNetwork", "wifi_password": "secret123", "wifi_security": "WPA"]
                    ],
                    [
                        "type": "contact",
                        "required_fields": ["contact_name"],
                        "optional_fields": ["contact_phone", "contact_email", "contact_organization", "contact_url"],
                        "example": ["title": "John Doe", "type": "contact", "contact_name": "John Doe", "contact_phone": "+1234567890", "contact_email": "john@example.com"]
                    ],
                    [
                        "type": "calendar",
                        "required_fields": ["event_title", "event_start_date"],
                        "optional_fields": ["event_end_date", "event_start_time", "event_end_time", "event_location", "event_description", "event_all_day (true/false)"],
                        "example": ["title": "Team Meeting", "type": "calendar", "event_title": "Weekly Standup", "event_start_date": "2025-03-15", "event_start_time": "09:00", "event_end_time": "09:30"]
                    ],
                    [
                        "type": "venmo",
                        "required_fields": ["data"],
                        "note": "data = Venmo username (with or without @)",
                        "example": ["title": "Pay Me on Venmo", "type": "venmo", "data": "@username"]
                    ],
                    [
                        "type": "paypal",
                        "required_fields": ["data"],
                        "note": "data = PayPal.me username or email",
                        "example": ["title": "PayPal Link", "type": "paypal", "data": "myusername"]
                    ],
                    [
                        "type": "cashapp",
                        "required_fields": ["data"],
                        "note": "data = Cash App $cashtag",
                        "example": ["title": "Cash App", "type": "cashapp", "data": "$mycashtag"]
                    ],
                    [
                        "type": "zelle",
                        "required_fields": ["data"],
                        "note": "data = Zelle email or phone number",
                        "example": ["title": "Zelle Payment", "type": "zelle", "data": "email@example.com"]
                    ],
                    [
                        "type": "crypto",
                        "required_fields": ["data"],
                        "note": "data = wallet address or payment URI",
                        "example": ["title": "BTC Wallet", "type": "crypto", "data": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"]
                    ],
                    [
                        "type": "file",
                        "required_fields": ["data"],
                        "note": "data = URL to the file",
                        "example": ["title": "Company Brochure", "type": "file", "data": "https://example.com/brochure.pdf"]
                    ]
                ]
            ],
            "qr_codes": [
                [
                    "title": "Example — delete this and add your own",
                    "type": "url",
                    "data": "https://example.com",
                    "tags": ["sample"],
                    "is_favorite": false
                ] as [String: Any]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: template, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }

    // MARK: - Import

    static func importFromJSON(_ jsonString: String, into context: ModelContext) -> BulkImportResult {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return BulkImportResult(successCount: 0, errors: [
                BulkImportError(index: 0, title: nil, message: "Could not read the JSON text. Make sure it's valid UTF-8.")
            ])
        }

        let file: BulkImportFile
        do {
            file = try JSONDecoder().decode(BulkImportFile.self, from: jsonData)
        } catch {
            return BulkImportResult(successCount: 0, errors: [
                BulkImportError(index: 0, title: nil, message: "Invalid JSON format: \(error.localizedDescription)")
            ])
        }

        if file.qr_codes.isEmpty {
            return BulkImportResult(successCount: 0, errors: [
                BulkImportError(index: 0, title: nil, message: "The qr_codes array is empty. Add at least one QR code entry.")
            ])
        }

        var successCount = 0
        var errors: [BulkImportError] = []

        for (index, item) in file.qr_codes.enumerated() {
            switch processItem(item, index: index) {
            case .success(let qrCode):
                context.insert(qrCode)
                successCount += 1
            case .failure(let error):
                errors.append(error)
            }
        }

        if successCount > 0 {
            try? context.save()
        }

        return BulkImportResult(successCount: successCount, errors: errors)
    }

    // MARK: - Private Helpers

    private static func processItem(_ item: BulkImportItem, index: Int) -> Result<QRCode, BulkImportError> {
        // Validate title
        guard let title = item.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(BulkImportError(index: index + 1, title: item.title, message: "Missing required field: title"))
        }

        if let titleError = Validation.validateTitle(title) {
            return .failure(BulkImportError(index: index + 1, title: title, message: titleError))
        }

        // Resolve type
        guard let typeString = item.type,
              let qrType = QRType(rawValue: typeString.lowercased()) else {
            let validTypes = QRType.allCases.map(\.rawValue).joined(separator: ", ")
            return .failure(BulkImportError(index: index + 1, title: title, message: "Invalid or missing type. Valid types: \(validTypes)"))
        }

        // Validate and encode data
        let encodedData: String
        switch validateAndEncodeData(for: item, type: qrType) {
        case .success(let data):
            encodedData = data
        case .failure(let error):
            return .failure(BulkImportError(index: index + 1, title: title, message: error.message))
        }

        // Build QRCode
        let errorCorrection: ErrorCorrectionLevel
        if let ecRaw = item.error_correction, let ec = ErrorCorrectionLevel(rawValue: ecRaw.uppercased()) {
            errorCorrection = ec
        } else {
            errorCorrection = .M
        }

        let size = item.size ?? 512
        let tags = item.tags ?? []
        let isFavorite = item.is_favorite ?? false

        // Validate tags
        for tag in tags {
            if let tagError = Validation.validateTag(tag) {
                return .failure(BulkImportError(index: index + 1, title: title, message: "Invalid tag '\(tag)': \(tagError)"))
            }
        }

        let qrCode = QRCode(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            data: encodedData,
            type: qrType,
            tags: tags,
            isFavorite: isFavorite,
            errorCorrection: errorCorrection,
            sizePx: size
        )

        return .success(qrCode)
    }

    private static func validateAndEncodeData(for item: BulkImportItem, type: QRType) -> Result<String, ValidationError> {
        switch type {
        case .url:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (URL)"))
            }
            let normalized = Validation.normalizeURL(data)
            if let error = Validation.validateURL(data) {
                return .failure(ValidationError(message: error))
            }
            return .success(normalized)

        case .file:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (file URL)"))
            }
            let normalized = Validation.normalizeURL(data)
            return .success(normalized)

        case .text:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (text content)"))
            }
            if let error = Validation.validateText(data) {
                return .failure(ValidationError(message: error))
            }
            return .success(data.trimmingCharacters(in: .whitespacesAndNewlines))

        case .wifi:
            guard let ssid = item.wifi_ssid, !ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: wifi_ssid"))
            }
            let security: WiFiData.Security
            if let secStr = item.wifi_security, let sec = WiFiData.Security(rawValue: secStr) {
                security = sec
            } else {
                security = .WPA
            }
            let wifiData = WiFiData(
                ssid: ssid,
                password: item.wifi_password ?? "",
                security: security,
                hidden: item.wifi_hidden ?? false
            )
            return .success(QRDataEncoder.encodeWiFi(wifiData))

        case .contact:
            guard let name = item.contact_name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: contact_name"))
            }
            let contactData = ContactData(
                name: name,
                phone: item.contact_phone ?? "",
                email: item.contact_email ?? "",
                organization: item.contact_organization ?? "",
                url: item.contact_url ?? ""
            )
            return .success(QRDataEncoder.encodeContact(contactData))

        case .calendar:
            guard let eventTitle = item.event_title, !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: event_title"))
            }
            guard let startDateStr = item.event_start_date, !startDateStr.isEmpty else {
                return .failure(ValidationError(message: "Missing required field: event_start_date (format: YYYY-MM-DD)"))
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            guard let startDate = dateFormatter.date(from: startDateStr) else {
                return .failure(ValidationError(message: "Invalid event_start_date format. Use YYYY-MM-DD (e.g. 2025-03-15)"))
            }

            let endDate: Date
            if let endDateStr = item.event_end_date, !endDateStr.isEmpty {
                guard let parsed = dateFormatter.date(from: endDateStr) else {
                    return .failure(ValidationError(message: "Invalid event_end_date format. Use YYYY-MM-DD (e.g. 2025-03-15)"))
                }
                endDate = parsed
            } else {
                endDate = startDate
            }

            let isAllDay = item.event_all_day ?? (item.event_start_time == nil)

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")

            let startTime: Date
            if let startTimeStr = item.event_start_time, !startTimeStr.isEmpty {
                guard let parsed = timeFormatter.date(from: startTimeStr) else {
                    return .failure(ValidationError(message: "Invalid event_start_time format. Use HH:MM 24-hour (e.g. 09:00)"))
                }
                startTime = parsed
            } else {
                startTime = .now
            }

            let endTime: Date
            if let endTimeStr = item.event_end_time, !endTimeStr.isEmpty {
                guard let parsed = timeFormatter.date(from: endTimeStr) else {
                    return .failure(ValidationError(message: "Invalid event_end_time format. Use HH:MM 24-hour (e.g. 17:00)"))
                }
                endTime = parsed
            } else {
                endTime = startTime
            }

            let eventData = CalendarEventData(
                title: eventTitle,
                startDate: startDate,
                endDate: endDate,
                startTime: startTime,
                endTime: endTime,
                location: item.event_location ?? "",
                eventDescription: item.event_description ?? "",
                allDay: isAllDay
            )
            return .success(QRDataEncoder.encodeCalendarEvent(eventData))

        case .venmo:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (Venmo username)"))
            }
            return .success(QRDataEncoder.encodeVenmo(data))

        case .paypal:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (PayPal username or email)"))
            }
            return .success(QRDataEncoder.encodePayPal(data))

        case .cashapp:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (Cash App $cashtag)"))
            }
            return .success(QRDataEncoder.encodeCashApp(data))

        case .zelle:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (Zelle email or phone)"))
            }
            return .success(QRDataEncoder.encodeZelle(data))

        case .crypto:
            guard let data = item.data, !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ValidationError(message: "Missing required field: data (wallet address)"))
            }
            return .success(data.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
