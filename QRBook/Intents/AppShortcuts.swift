import AppIntents

struct QRBookShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowQRCodeIntent(),
            phrases: [
                "Show \(\.$qrCode) in \(.applicationName)",
                "Open \(\.$qrCode) in \(.applicationName)"
            ],
            shortTitle: "Show QR Code",
            systemImageName: "qrcode"
        )

        AppShortcut(
            intent: CreateQRCodeIntent(),
            phrases: [
                "Create a QR code in \(.applicationName)",
                "Make a QR code in \(.applicationName)"
            ],
            shortTitle: "Create QR Code",
            systemImageName: "plus.circle"
        )
    }
}
