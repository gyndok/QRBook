import SwiftUI
import SwiftData

struct QRHistoryView: View {
    let qrCodeId: UUID
    @Query private var allEvents: [ScanEvent]

    private var events: [ScanEvent] {
        allEvents.filter { $0.qrCodeId == qrCodeId }.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Total Views", value: "\(events.count)")
                if let first = events.last {
                    LabeledContent("First Viewed", value: first.timestamp.relativeFormatted)
                }
                if let last = events.first {
                    LabeledContent("Last Viewed", value: last.timestamp.relativeFormatted)
                }
            }

            Section("Timeline") {
                if events.isEmpty {
                    Text("No scan history yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        HStack {
                            Image(systemName: "eye")
                                .foregroundStyle(Color.electricViolet)
                            Text(event.timestamp, style: .date)
                            Text(event.timestamp, style: .time)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Scan History")
    }
}
