import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            close()
            return
        }

        for provider in itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    if let url = item as? URL {
                        self?.saveSharedItem(data: url.absoluteString, type: "url")
                    }
                }
                return
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    if let text = item as? String {
                        self?.saveSharedItem(data: text, type: "text")
                    }
                }
                return
            }
        }
        close()
    }

    private func saveSharedItem(data: String, type: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else {
            DispatchQueue.main.async { [weak self] in self?.close() }
            return
        }

        let payload: [String: String] = [
            "data": data,
            "type": type,
            "timestamp": ISO8601DateFormatter().string(from: .now)
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload) {
            let fileURL = containerURL.appendingPathComponent("shared-import-\(UUID().uuidString).json")
            try? jsonData.write(to: fileURL)
        }

        DispatchQueue.main.async { [weak self] in
            self?.close()
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
