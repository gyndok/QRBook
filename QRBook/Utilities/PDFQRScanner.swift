import CoreImage
import Foundation
import PDFKit
import Vision

/// A QR/barcode detected within a PDF document.
struct DetectedQRCode: Identifiable, Hashable {
    let id: UUID
    let payload: String
    let symbology: VNBarcodeSymbology
    var pageNumbers: [Int]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DetectedQRCode, rhs: DetectedQRCode) -> Bool {
        lhs.id == rhs.id
    }
}

enum PDFScanError: Error, LocalizedError {
    case unableToOpenPDF
    case noPages

    var errorDescription: String? {
        switch self {
        case .unableToOpenPDF:
            return "Unable to read this PDF. It may be password-protected."
        case .noPages:
            return "This PDF has no pages."
        }
    }
}

enum PDFQRScanner {

    /// Scans all pages of a PDF for QR codes and barcodes.
    static func scanPDF(
        url: URL,
        progressHandler: @escaping @Sendable (Int, Int) -> Void = { _, _ in }
    ) async throws -> [DetectedQRCode] {
        guard let document = PDFDocument(url: url) else {
            throw PDFScanError.unableToOpenPDF
        }

        let pageCount = document.pageCount
        guard pageCount > 0 else {
            throw PDFScanError.noPages
        }

        var allDetected: [DetectedQRCode] = []

        for pageIndex in 0..<pageCount {
            try Task.checkCancellation()
            await MainActor.run { progressHandler(pageIndex + 1, pageCount) }

            guard let page = document.page(at: pageIndex),
                  let cgImage = renderPage(page) else {
                continue
            }

            let barcodes = try await detectBarcodes(in: cgImage)

            for barcode in barcodes {
                if let existingIndex = allDetected.firstIndex(where: { $0.payload == barcode.payload }) {
                    if !allDetected[existingIndex].pageNumbers.contains(pageIndex + 1) {
                        allDetected[existingIndex].pageNumbers.append(pageIndex + 1)
                    }
                } else {
                    var newBarcode = barcode
                    newBarcode.pageNumbers = [pageIndex + 1]
                    allDetected.append(newBarcode)
                }
            }
        }

        return allDetected
    }

    private static func renderPage(_ page: PDFPage, dpi: CGFloat = 200) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let scale = dpi / 72.0
        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: scale, y: scale)

        page.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }

    private static func detectBarcodes(in image: CGImage) async throws -> [DetectedQRCode] {
        do {
            return try detectBarcodesWithVision(in: image)
        } catch {
            // Vision framework may not have GPU/ANE support (e.g. on Simulator).
            // Fall back to CIDetector which works everywhere.
            return detectBarcodesWithCIDetector(in: image)
        }
    }

    private static func detectBarcodesWithVision(in image: CGImage) throws -> [DetectedQRCode] {
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        try handler.perform([request])

        let results = (request.results as? [VNBarcodeObservation]) ?? []
        return results.compactMap { observation -> DetectedQRCode? in
            guard let payload = observation.payloadStringValue else { return nil }
            return DetectedQRCode(
                id: UUID(),
                payload: payload,
                symbology: observation.symbology,
                pageNumbers: []
            )
        }
    }

    private static func detectBarcodesWithCIDetector(in image: CGImage) -> [DetectedQRCode] {
        let ciImage = CIImage(cgImage: image)
        guard let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        ) else { return [] }

        let features = detector.features(in: ciImage)
        return features.compactMap { feature -> DetectedQRCode? in
            guard let qrFeature = feature as? CIQRCodeFeature,
                  let payload = qrFeature.messageString else { return nil }
            return DetectedQRCode(
                id: UUID(),
                payload: payload,
                symbology: .qr,
                pageNumbers: []
            )
        }
    }
}
