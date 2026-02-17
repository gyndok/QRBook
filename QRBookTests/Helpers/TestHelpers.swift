import Foundation
@testable import QRBook

enum TestData {

    static func makeQRCode(
        title: String = "Test QR",
        data: String = "https://example.com",
        type: QRType = .url,
        tags: [String] = [],
        isFavorite: Bool = false,
        scanCount: Int = 0,
        createdAt: Date = Date(),
        lastUsed: Date? = nil,
        folderName: String = ""
    ) -> QRCode {
        QRCode(
            title: title,
            data: data,
            type: type,
            tags: tags,
            isFavorite: isFavorite,
            scanCount: scanCount,
            createdAt: createdAt,
            lastUsed: lastUsed,
            folderName: folderName
        )
    }

    static func makeWiFiData(
        ssid: String = "MyNetwork",
        password: String = "password123",
        security: WiFiData.Security = .WPA,
        hidden: Bool = false
    ) -> WiFiData {
        WiFiData(ssid: ssid, password: password, security: security, hidden: hidden)
    }

    static func makeContactData(
        name: String = "John Doe",
        phone: String = "555-1234",
        email: String = "john@example.com",
        organization: String = "Acme Inc",
        url: String = "https://example.com"
    ) -> ContactData {
        ContactData(name: name, phone: phone, email: email, organization: organization, url: url)
    }

    static func makeCalendarEventData(
        title: String = "Team Meeting",
        startDate: Date = fixedDate(year: 2026, month: 3, day: 15),
        endDate: Date = fixedDate(year: 2026, month: 3, day: 15),
        startTime: Date = fixedTime(hour: 9, minute: 0),
        endTime: Date = fixedTime(hour: 10, minute: 0),
        location: String = "Room 101",
        eventDescription: String = "Weekly sync",
        allDay: Bool = false
    ) -> CalendarEventData {
        CalendarEventData(
            title: title,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime,
            location: location,
            eventDescription: eventDescription,
            allDay: allDay
        )
    }

    static func fixedDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    static func fixedTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
