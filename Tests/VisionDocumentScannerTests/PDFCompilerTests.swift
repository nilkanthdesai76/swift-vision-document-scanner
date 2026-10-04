import XCTest
@testable import VisionDocumentScanner
import CoreGraphics

final class PDFCompilerTests: XCTestCase {

    private func makeTestPage(color: CGColor) -> CGImage {
        let width = 200
        let height = 300
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    func testPDFCompilationMultiplePages() {
        let page1 = makeTestPage(color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        let page2 = makeTestPage(color: CGColor(red: 0, green: 1, blue: 0, alpha: 1))
        let page3 = makeTestPage(color: CGColor(red: 0, green: 0, blue: 1, alpha: 1))

        let compiler = PDFCompiler.shared
        let pdfData = compiler.compile(
            images: [page1, page2, page3],
            pageSize: .a4(margin: 15.0),
            metadata: PDFMetadata(title: "Test Scan", author: "Antigravity")
        )

        XCTAssertNotNil(pdfData)
        guard let data = pdfData else { return }

        // PDF files start with %PDF-
        let headerPrefix = String(data: data.prefix(5), encoding: .utf8)
        XCTAssertEqual(headerPrefix, "%PDF-")
        XCTAssertGreaterThan(data.count, 500)
    }

    func testPDFCompilationMatchImageSize() {
        let page = makeTestPage(color: CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        let compiler = PDFCompiler.shared
        let pdfData = compiler.compile(images: [page], pageSize: .matchImageSize)

        XCTAssertNotNil(pdfData)
    }

    func testEmptyImagesReturnsNil() {
        let compiler = PDFCompiler.shared
        let result = compiler.compile(images: [])
        XCTAssertNil(result)
    }
}
