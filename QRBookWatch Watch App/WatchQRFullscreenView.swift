import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct WatchQRFullscreenView: View {
    let data: String
    let title: String

    var body: some View {
        VStack {
            if let image = generateQR(from: data, size: 150) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
    }

    private func generateQR(from string: String, size: CGFloat) -> UIImage? {
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
}
