import XCTest
import PDFKit
@testable import QRBook

final class PDFQRScannerTests: XCTestCase {

    // MARK: - Helpers

    private func createBlankPDF() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-blank-\(UUID()).pdf")
        let pdfDocument = PDFDocument()
        let page = PDFPage()
        pdfDocument.insert(page, at: 0)
        pdfDocument.write(to: url)
        return url
    }

    private func createPDFWithQRCode(payload: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-qr-\(UUID()).pdf")

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            fatalError("CIQRCodeGenerator not available")
        }
        filter.setValue(payload.data(using: .utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else {
            fatalError("Could not generate QR image")
        }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            fatalError("Could not create CGImage")
        }

        let qrImage = UIImage(cgImage: cgImage)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            qrImage.draw(in: CGRect(x: 100, y: 100, width: 200, height: 200))
        }
        try! data.write(to: url)
        return url
    }

    private func createMultiPagePDF(payloads: [String]) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-multi-\(UUID()).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let context = CIContext()

        let data = renderer.pdfData { ctx in
            for payload in payloads {
                ctx.beginPage()

                guard let filter = CIFilter(name: "CIQRCodeGenerator") else { continue }
                filter.setValue(payload.data(using: .utf8), forKey: "inputMessage")
                filter.setValue("M", forKey: "inputCorrectionLevel")

                guard let ciImage = filter.outputImage else { continue }
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = ciImage.transformed(by: transform)
                guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { continue }

                UIImage(cgImage: cgImage).draw(in: CGRect(x: 100, y: 100, width: 200, height: 200))
            }
        }
        try! data.write(to: url)
        return url
    }

    // MARK: - Tests

    func test_scanPDF_blankPDF_returnsEmpty() async throws {
        let url = createBlankPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let results = try await PDFQRScanner.scanPDF(url: url)
        XCTAssertTrue(results.isEmpty)
    }

    func test_scanPDF_singleQRCode_returnsOneResult() async throws {
        let payload = "https://example.com/boarding-pass"
        let url = createPDFWithQRCode(payload: payload)
        defer { try? FileManager.default.removeItem(at: url) }

        let results = try await PDFQRScanner.scanPDF(url: url)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.payload, payload)
        XCTAssertEqual(results.first?.pageNumbers, [1])
    }

    func test_scanPDF_multiplePages_deduplicates() async throws {
        let payload = "https://example.com/same-code"
        let url = createMultiPagePDF(payloads: [payload, payload])
        defer { try? FileManager.default.removeItem(at: url) }

        let results = try await PDFQRScanner.scanPDF(url: url)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.pageNumbers, [1, 2])
    }

    func test_scanPDF_differentQRsOnDifferentPages_returnsAll() async throws {
        let url = createMultiPagePDF(payloads: ["https://a.com", "https://b.com"])
        defer { try? FileManager.default.removeItem(at: url) }

        let results = try await PDFQRScanner.scanPDF(url: url)
        XCTAssertEqual(results.count, 2)
        let payloads = Set(results.map(\.payload))
        XCTAssertTrue(payloads.contains("https://a.com"))
        XCTAssertTrue(payloads.contains("https://b.com"))
    }

    func test_scanPDF_rotatedPage_detectsQRCode() async throws {
        // Scanned documents commonly carry a /Rotate 90 page attribute;
        // rendering must honor it or the QR is clipped/warped and missed.
        let payload = "https://example.com/rotated"
        let originalURL = createPDFWithQRCode(payload: payload)
        defer { try? FileManager.default.removeItem(at: originalURL) }

        let document = try XCTUnwrap(PDFDocument(url: originalURL))
        let page = try XCTUnwrap(document.page(at: 0))
        page.rotation = 90
        let rotatedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-rotated-\(UUID()).pdf")
        document.write(to: rotatedURL)
        defer { try? FileManager.default.removeItem(at: rotatedURL) }

        let results = try await PDFQRScanner.scanPDF(url: rotatedURL)
        XCTAssertEqual(results.first?.payload, payload)
    }

    func test_scanPDF_invalidURL_throwsError() async {
        let fakeURL = URL(fileURLWithPath: "/nonexistent/file.pdf")
        do {
            _ = try await PDFQRScanner.scanPDF(url: fakeURL)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is PDFScanError)
        }
    }

    func test_scanPDF_reportsProgress() async throws {
        let url = createMultiPagePDF(payloads: ["https://a.com", "https://b.com", "https://c.com"])
        defer { try? FileManager.default.removeItem(at: url) }

        var progressUpdates: [(Int, Int)] = []
        let results = try await PDFQRScanner.scanPDF(url: url) { current, total in
            progressUpdates.append((current, total))
        }

        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(progressUpdates.count, 3)
        XCTAssertEqual(progressUpdates.last?.0, 3)
        XCTAssertEqual(progressUpdates.last?.1, 3)
    }
}
