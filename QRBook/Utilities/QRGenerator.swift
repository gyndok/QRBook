import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRGenerator {
    static func generateQRCode(
        from string: String,
        correctionLevel: ErrorCorrectionLevel = .M,
        size: CGFloat = 512
    ) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue

        guard let ciImage = filter.outputImage else { return nil }

        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    static func generateQRImage(for qrCode: QRCode) -> UIImage? {
        generateQRCode(
            from: qrCode.data,
            correctionLevel: qrCode.errorCorrection,
            size: CGFloat(qrCode.sizePx)
        )
    }
}
