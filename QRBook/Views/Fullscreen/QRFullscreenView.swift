import SwiftUI

struct QRFullscreenView: View {
    @Bindable var qrCode: QRCode
    let allQRCodes: [QRCode]
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var brightnessBoost = false
    @State private var previousBrightness: CGFloat = 0.5
    @State private var dragOffset: CGFloat = 0

    private var currentQR: QRCode {
        guard currentIndex >= 0, currentIndex < allQRCodes.count else { return qrCode }
        return allQRCodes[currentIndex]
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
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
                    size: 320
                ) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .padding(32)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 20)
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    withAnimation(.spring(response: 0.3)) {
                                        if value.translation.width < -threshold, currentIndex < allQRCodes.count - 1 {
                                            currentIndex += 1
                                            recordScan()
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } else if value.translation.width > threshold, currentIndex > 0 {
                                            currentIndex -= 1
                                            recordScan()
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )
                }

                Spacer()

                // Bottom info
                VStack(spacing: 4) {
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
            currentIndex = allQRCodes.firstIndex(where: { $0.id == qrCode.id }) ?? 0
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
    }

    private func saveToPhotos() {
        guard let image = QRGenerator.generateQRCode(
            from: currentQR.data,
            correctionLevel: currentQR.errorCorrection,
            size: CGFloat(currentQR.sizePx)
        ) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
