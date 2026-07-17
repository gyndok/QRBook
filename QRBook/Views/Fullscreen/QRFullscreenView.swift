import Photos
import SwiftUI
import SwiftData

struct QRFullscreenView: View {
    @Bindable var qrCode: QRCode
    let allQRCodes: [QRCode]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    // Track the displayed card by identity, not by list index: under the
    // "Recent" sort, recordScan() bumps lastUsed and the @Query re-sorts the
    // list while the cover is open, so a stored index would point at a
    // different card.
    @State private var currentID: UUID
    @State private var brightnessBoost = false
    @State private var previousBrightness: CGFloat = 0.5
    @State private var dragOffset: CGFloat = 0
    @State private var showEditSheet = false
    @State private var showHistory = false
    @State private var showPhotoSaveError = false

    init(qrCode: QRCode, allQRCodes: [QRCode]) {
        self._qrCode = Bindable(qrCode)
        self.allQRCodes = allQRCodes
        self._currentID = State(initialValue: qrCode.id)
    }

    /// Resolves the displayed card by identity so a live re-sort of the list
    /// can't leave a stored index pointing at the wrong card.
    static func resolvedCard(id: UUID, in allQRCodes: [QRCode], fallback: QRCode) -> QRCode {
        allQRCodes.first { $0.id == id } ?? fallback
    }

    private var currentQR: QRCode {
        Self.resolvedCard(id: currentID, in: allQRCodes, fallback: qrCode)
    }

    private var currentIndex: Int {
        allQRCodes.firstIndex { $0.id == currentID } ?? 0
    }

    var body: some View {
        ZStack {
            // Dark background with radial glow
            Color.black
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            AppTheme.fullscreenRadialGlow
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }

                    Button { showEditSheet = true } label: {
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }

                    Text(currentQR.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        toggleBrightness()
                    } label: {
                        Image(systemName: brightnessBoost ? "sun.max.fill" : "sun.max")
                            .font(.title3)
                            .foregroundStyle(brightnessBoost ? .yellow : .white)
                            .padding(8)
                    }

                    ShareLink(item: currentQR.data) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }

                    Button {
                        saveToPhotos()
                    } label: {
                        Image(systemName: "arrow.down.to.line")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // QR code card
                if let uiImage = QRGenerator.generateQRCode(
                    from: currentQR.data,
                    correctionLevel: currentQR.errorCorrection,
                    size: 320,
                    foregroundHex: currentQR.foregroundHex,
                    backgroundHex: currentQR.backgroundHex,
                    logoImageData: currentQR.logoImageData
                ) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .padding(32)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.electricViolet.opacity(0.3), radius: 30)
                        .shadow(radius: 20)
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    let idx = currentIndex
                                    withAnimation(.spring(response: 0.3)) {
                                        if value.translation.width < -threshold, idx < allQRCodes.count - 1 {
                                            currentID = allQRCodes[idx + 1].id
                                            recordScan()
                                            HapticManager.impact()
                                        } else if value.translation.width > threshold, idx > 0 {
                                            currentID = allQRCodes[idx - 1].id
                                            recordScan()
                                            HapticManager.impact()
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )
                }

                Spacer()

                // Bottom info
                VStack(spacing: 4) {
                    Button { showHistory = true } label: {
                        Label("Scan History", systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    if allQRCodes.count > 1 {
                        Text("\(currentIndex + 1) of \(allQRCodes.count)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Text("Swipe to navigate \u{2022} Tap background to close")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            if qrCode.brightnessBoostDefault {
                brightnessBoost = true
                UIScreen.main.brightness = 1.0
            }
            UIApplication.shared.isIdleTimerDisabled = true
            recordScan()
        }
        .onDisappear {
            if brightnessBoost {
                UIScreen.main.brightness = previousBrightness
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .statusBarHidden()
        .sheet(isPresented: $showEditSheet) {
            EditQRView(qrCode: currentQR)
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                QRHistoryView(qrCodeId: currentQR.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showHistory = false }
                        }
                    }
            }
        }
        .alert("Couldn't Save Photo", isPresented: $showPhotoSaveError) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Allow photo library access in Settings to save QR codes.")
        }
    }

    private func toggleBrightness() {
        brightnessBoost.toggle()
        if brightnessBoost {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        } else {
            UIScreen.main.brightness = previousBrightness
        }
    }

    private func recordScan() {
        currentQR.scanCount += 1
        currentQR.lastUsed = .now
        let event = ScanEvent(qrCodeId: currentQR.id)
        modelContext.insert(event)
    }

    private func saveToPhotos() {
        guard let image = QRGenerator.generateQRCode(
            from: currentQR.data,
            correctionLevel: currentQR.errorCorrection,
            size: CGFloat(currentQR.sizePx),
            foregroundHex: currentQR.foregroundHex,
            backgroundHex: currentQR.backgroundHex,
            logoImageData: currentQR.logoImageData
        ) else { return }
        // UIImageWriteToSavedPhotosAlbum with no completion fails silently
        // when photo-add permission is denied while the haptic still signals
        // success; performChanges reports the real outcome.
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, _ in
            DispatchQueue.main.async {
                if success {
                    HapticManager.success()
                } else {
                    showPhotoSaveError = true
                }
            }
        }
    }
}
