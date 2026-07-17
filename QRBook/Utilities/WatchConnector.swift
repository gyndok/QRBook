import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnector()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendFavorites(_ favorites: [QRCode]) {
        guard WCSession.default.activationState == .activated else { return }
        let items = favorites.map { qr -> [String: String] in
            var item = ["id": qr.id.uuidString, "title": qr.title, "data": qr.data, "type": qr.typeRaw]
            // watchOS has no CoreImage, so the QR image is rendered here and shipped as PNG.
            // Plain black-on-white at 200px keeps each entry to a few KB.
            if let image = QRGenerator.generateQRCode(from: qr.data, size: 200),
               let png = image.pngData() {
                item["image"] = png.base64EncodedString()
            }
            return item
        }
        guard let data = try? JSONSerialization.data(withJSONObject: items) else { return }
        try? WCSession.default.updateApplicationContext(["favorites": data])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
