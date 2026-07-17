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
            // PDF must be checked before URL: a shared PDF arrives as a file URL,
            // which conforms to public.url and would be captured as a "url" import.
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { [weak self] item, _ in
                    if let url = item as? URL {
                        self?.copyPDFToAppGroup(from: url)
                    } else if let data = item as? Data {
                        self?.savePDFDataToAppGroup(data)
                    } else {
                        DispatchQueue.main.async { self?.close() }
                    }
                }
                return
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    if let url = item as? URL, !url.isFileURL {
                        self?.saveSharedItem(data: url.absoluteString, type: "url")
                    } else {
                        DispatchQueue.main.async { self?.close() }
                    }
                }
                return
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    if let text = item as? String {
                        self?.saveSharedItem(data: text, type: "text")
                    } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                        self?.saveSharedItem(data: text, type: "text")
                    } else {
                        DispatchQueue.main.async { self?.close() }
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

    private func copyPDFToAppGroup(from sourceURL: URL) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else {
            DispatchQueue.main.async { [weak self] in self?.close() }
            return
        }

        let destURL = containerURL.appendingPathComponent("shared-pdf-\(UUID().uuidString).pdf")
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        try? FileManager.default.copyItem(at: sourceURL, to: destURL)
        if accessing {
            sourceURL.stopAccessingSecurityScopedResource()
        }

        DispatchQueue.main.async { [weak self] in
            self?.close()
        }
    }

    private func savePDFDataToAppGroup(_ data: Data) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else {
            DispatchQueue.main.async { [weak self] in self?.close() }
            return
        }

        let destURL = containerURL.appendingPathComponent("shared-pdf-\(UUID().uuidString).pdf")
        try? data.write(to: destURL)

        DispatchQueue.main.async { [weak self] in
            self?.close()
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
