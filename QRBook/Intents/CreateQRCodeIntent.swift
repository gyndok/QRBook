import AppIntents

struct CreateQRCodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Create QR Code"
    static var description = IntentDescription("Opens QR Book to create a new QR code")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
