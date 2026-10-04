import XCTest
@testable import VisionDocumentScanner
import CoreGraphics

final class DocumentProcessorTests: XCTestCase {

    private func makeTestImage(width: Int = 200, height: Int = 300) -> CGImage {
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

        // Draw dark background
        context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw white card inside
        context.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
        context.fill(CGRect(x: 20, y: 30, width: width - 40, height: height - 60))

        // Draw some colorful lines
        context.setStrokeColor(CGColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0))
        context.setLineWidth(4.0)
        context.strokeLineSegments(between: [CGPoint(x: 40, y: 50), CGPoint(x: 160, y: 50)])

        return context.makeImage()!
    }

    func testPerspectiveCorrectionOriginal() {
        let image = makeTestImage()
        let processor = DocumentProcessor.shared

        // Inset quad matching the white card
        let quad = Quadrilateral(
            topLeft: CGPoint(x: 20, y: 30),
            topRight: CGPoint(x: 180, y: 30),
            bottomRight: CGPoint(x: 180, y: 270),
            bottomLeft: CGPoint(x: 20, y: 270)
        )

        let processed = processor.process(image: image, quadrilateral: quad, filter: .original)
        XCTAssertNotNil(processed)
        if let out = processed {
            XCTAssertGreaterThan(out.width, 0)
            XCTAssertGreaterThan(out.height, 0)
        }
    }

    func testAllFiltersProduceValidImages() {
        let image = makeTestImage()
        let processor = DocumentProcessor.shared
        let quad = Quadrilateral.standardInset(bounds: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        for filter in ScanFilter.allCases {
            let processed = processor.process(image: image, quadrilateral: quad, filter: filter)
            XCTAssertNotNil(processed, "Filter \(filter) should produce valid CGImage")
        }
    }

    func testEstimateTargetSize() {
        let quad = Quadrilateral(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: 300, y: 0),
            bottomRight: CGPoint(x: 300, y: 400),
            bottomLeft: CGPoint(x: 0, y: 400)
        )
        let size = DocumentProcessor.estimateTargetSize(quadrilateral: quad)
        XCTAssertEqual(size.width, 300, accuracy: 1.0)
        XCTAssertEqual(size.height, 400, accuracy: 1.0)
    }
}
