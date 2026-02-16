import SwiftUI
import VisionKit

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var scannedCode: String?
    @State private var detectedType: QRType = .text
    @State private var showSaveSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(scannedCode: $scannedCode)
                        .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Scanner Unavailable",
                        systemImage: "camera.fill",
                        description: Text("Camera scanning is not available on this device.")
                    )
                }

                if let code = scannedCode {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: detectedType.icon)
                                    .foregroundStyle(Color.electricViolet)
                                Text("QR Code Detected")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    scannedCode = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(code)
                                .font(.subheadline)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                Button {
                                    showSaveSheet = true
                                } label: {
                                    Label("Save", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.electricViolet)

                                Button {
                                    UIPasteboard.general.string = code
                                    HapticManager.success()
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)

                                if code.hasPrefix("http") {
                                    Link(destination: URL(string: code) ?? URL(string: "https://example.com")!) {
                                        Label("Open", systemImage: "safari")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                    }
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scannedCode) {
                if let code = scannedCode {
                    detectedType = detectType(code)
                    HapticManager.success()
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                CreateQRView(prefillData: scannedCode, prefillType: detectedType)
            }
        }
    }

    private func detectType(_ data: String) -> QRType {
        if data.hasPrefix("WIFI:") { return .wifi }
        if data.contains("BEGIN:VCARD") { return .contact }
        if data.contains("BEGIN:VCALENDAR") { return .calendar }
        if data.hasPrefix("http://") || data.hasPrefix("https://") { return .url }
        return .text
    }
}

struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: DataScannerRepresentable
        init(_ parent: DataScannerRepresentable) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case .barcode(let barcode) = item {
                parent.scannedCode = barcode.payloadStringValue
            }
        }
    }
}
