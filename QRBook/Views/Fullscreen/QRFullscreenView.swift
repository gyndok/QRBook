import SwiftUI

// Stub — will be replaced in Task 12
struct QRFullscreenView: View {
    @Bindable var qrCode: QRCode
    let allQRCodes: [QRCode]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                Spacer()

                if let uiImage = QRGenerator.generateQRCode(
                    from: qrCode.data,
                    correctionLevel: qrCode.errorCorrection,
                    size: 280
                ) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .padding(32)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                Text(qrCode.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 16)

                Spacer()
            }
        }
        .statusBarHidden()
    }
}
