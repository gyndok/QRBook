import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct QRGenerator {
    static func generateQRCode(
        from string: String,
        correctionLevel: ErrorCorrectionLevel = .M,
        size: CGFloat = 512,
        foregroundHex: String = "",
        backgroundHex: String = "",
        logoImageData: Data? = nil
    ) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue

        guard var ciImage = filter.outputImage else { return nil }

        // Apply custom colors via CIFalseColor
        if !foregroundHex.isEmpty || !backgroundHex.isEmpty {
            let fgColor = CIColor(color: UIColor(Color(hex: foregroundHex.isEmpty ? "000000" : foregroundHex)))
            let bgColor = CIColor(color: UIColor(Color(hex: backgroundHex.isEmpty ? "FFFFFF" : backgroundHex)))
            let colorFilter = CIFilter.falseColor()
            colorFilter.inputImage = ciImage
            colorFilter.color0 = fgColor
            colorFilter.color1 = bgColor
            if let colored = colorFilter.outputImage {
                ciImage = colored
            }
        }

        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        var result = UIImage(cgImage: cgImage)

        // Composite logo overlay if present
        if let logoData = logoImageData, let logo = UIImage(data: logoData) {
            result = compositeLogoOnQR(qrImage: result, logo: logo)
        }

        return result
    }

    static func generateQRImage(for qrCode: QRCode) -> UIImage? {
        generateQRCode(
            from: qrCode.data,
            correctionLevel: qrCode.errorCorrection,
            size: CGFloat(qrCode.sizePx),
            foregroundHex: qrCode.foregroundHex,
            backgroundHex: qrCode.backgroundHex,
            logoImageData: qrCode.logoImageData
        )
    }

    private static func compositeLogoOnQR(qrImage: UIImage, logo: UIImage) -> UIImage {
        let qrSize = qrImage.size
        let logoSize = CGSize(width: qrSize.width * 0.2, height: qrSize.height * 0.2)
        let logoOrigin = CGPoint(
            x: (qrSize.width - logoSize.width) / 2,
            y: (qrSize.height - logoSize.height) / 2
        )

        let renderer = UIGraphicsImageRenderer(size: qrSize)
        return renderer.image { _ in
            qrImage.draw(in: CGRect(origin: .zero, size: qrSize))

            // White background behind logo for contrast
            let padding: CGFloat = 4
            let bgRect = CGRect(
                x: logoOrigin.x - padding,
                y: logoOrigin.y - padding,
                width: logoSize.width + padding * 2,
                height: logoSize.height + padding * 2
            )
            UIColor.white.setFill()
            UIBezierPath(roundedRect: bgRect, cornerRadius: bgRect.width * 0.2).fill()

            // Draw logo clipped to rounded rect
            let logoRect = CGRect(origin: logoOrigin, size: logoSize)
            let ctx = UIGraphicsGetCurrentContext()
            ctx?.saveGState()
            UIBezierPath(roundedRect: logoRect, cornerRadius: logoRect.width * 0.15).addClip()
            logo.draw(in: logoRect)
            ctx?.restoreGState()
        }
    }
}
