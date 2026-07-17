import SwiftUI

struct WatchQRFullscreenView: View {
    let imageData: Data?
    let title: String

    var body: some View {
        VStack {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ContentUnavailableView(
                    "QR Unavailable",
                    systemImage: "qrcode",
                    description: Text("Open QRBook on your iPhone to sync.")
                )
            }
            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
    }
}
