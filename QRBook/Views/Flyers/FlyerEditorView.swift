import SwiftUI
import SwiftData

struct FlyerEditorView: View {
    let template: FlyerTemplate
    @Query private var qrCodes: [QRCode]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedQR: QRCode?
    @State private var title = "Your Title"
    @State private var subtitle = "Your subtitle text here"
    @State private var callToAction = "Scan Me!"
    @State private var backgroundColor: Color = .white
    @State private var accentColor: Color = Color(red: 124/255, green: 58/255, blue: 237/255)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live preview
                    flyerPreview
                        .frame(width: 300, height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)

                    // Edit fields
                    VStack(spacing: 12) {
                        Picker("QR Code", selection: $selectedQR) {
                            Text("Select a QR Code").tag(nil as QRCode?)
                            ForEach(qrCodes) { qr in
                                Text(qr.title).tag(qr as QRCode?)
                            }
                        }

                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                        TextField("Subtitle", text: $subtitle)
                            .textFieldStyle(.roundedBorder)
                        TextField("Call to Action", text: $callToAction)
                            .textFieldStyle(.roundedBorder)

                        ColorPicker("Background", selection: $backgroundColor, supportsOpacity: false)
                        ColorPicker("Accent", selection: $accentColor, supportsOpacity: false)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") { exportFlyer() }
                        .fontWeight(.semibold)
                        .disabled(selectedQR == nil)
                }
            }
        }
    }

    @ViewBuilder
    private var flyerPreview: some View {
        let qrData = selectedQR?.data ?? "https://example.com"

        switch template {
        case .clean:
            ZStack {
                backgroundColor
                VStack(spacing: 16) {
                    Text(title).font(.title2).fontWeight(.bold).foregroundStyle(accentColor)
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 160) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 160, height: 160)
                    }
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    Text(callToAction).font(.caption).fontWeight(.semibold).foregroundStyle(accentColor)
                }
                .padding()
            }

        case .banner:
            ZStack {
                backgroundColor
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title).font(.title).fontWeight(.bold).foregroundStyle(accentColor)
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text(callToAction).font(.caption).fontWeight(.bold).foregroundStyle(accentColor)
                    }
                    Spacer()
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 120) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 120, height: 120)
                    }
                }
                .padding()
            }

        case .poster:
            ZStack {
                LinearGradient(colors: [accentColor.opacity(0.15), backgroundColor], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 16) {
                    Text(title).font(.title).fontWeight(.black).foregroundStyle(accentColor)
                    Spacer()
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 180) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 180, height: 180)
                            .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Spacer()
                    Text(callToAction).font(.headline).foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(accentColor).clipShape(Capsule())
                }
                .padding()
            }

        case .minimal:
            ZStack {
                backgroundColor
                VStack {
                    HStack {
                        Text(title).font(.headline).foregroundStyle(accentColor)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        if let img = QRGenerator.generateQRCode(from: qrData, size: 100) {
                            Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 100, height: 100)
                        }
                    }
                }
                .padding()
            }

        case .card:
            ZStack {
                backgroundColor
                HStack(spacing: 16) {
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 140) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 140, height: 140)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title).font(.headline).foregroundStyle(accentColor)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(callToAction).font(.caption2).fontWeight(.bold).foregroundStyle(accentColor)
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }

    @MainActor
    private func exportFlyer() {
        let renderer = ImageRenderer(content: flyerPreview.frame(width: 600, height: 800))
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
        HapticManager.success()
    }
}
