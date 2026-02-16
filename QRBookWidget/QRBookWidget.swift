import WidgetKit
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct QRCodeWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let data: String
    let foregroundHex: String
    let backgroundHex: String
}

struct QRBookWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QRCodeWidgetEntry {
        QRCodeWidgetEntry(date: .now, title: "QR Code", data: "https://example.com", foregroundHex: "", backgroundHex: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (QRCodeWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QRCodeWidgetEntry>) -> Void) {
        let entries = loadEntries()
        let entry = entries.first ?? placeholder(in: context)
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func loadEntries() -> [QRCodeWidgetEntry] {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook")?
            .appendingPathComponent("widget-data.json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }

        return items.compactMap { item in
            guard let title = item["title"], let qrData = item["data"] else { return nil }
            return QRCodeWidgetEntry(
                date: .now,
                title: title,
                data: qrData,
                foregroundHex: item["foregroundHex"] ?? "",
                backgroundHex: item["backgroundHex"] ?? ""
            )
        }
    }
}

struct QRBookWidgetSmallView: View {
    let entry: QRCodeWidgetEntry

    var body: some View {
        VStack(spacing: 4) {
            if let image = generateWidgetQR(from: entry.data, size: 100) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            }
            Text(entry.title)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(8)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct QRBookWidgetMediumView: View {
    let entry: QRCodeWidgetEntry

    var body: some View {
        HStack {
            if let image = generateWidgetQR(from: entry.data, size: 120) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(2)
                Text("QR Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct QRBookWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QRBookWidget", provider: QRBookWidgetProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                QRBookWidgetSmallView(entry: entry)
            }
        }
        .configurationDisplayName("QR Book")
        .description("Display a QR code for quick access.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

func generateWidgetQR(from string: String, size: CGFloat) -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    guard let data = string.data(using: .utf8) else { return nil }
    filter.message = data
    filter.correctionLevel = "M"
    guard let ciImage = filter.outputImage else { return nil }
    let scale = size / ciImage.extent.size.width
    let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cgImage)
}
