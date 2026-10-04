import XCTest
@testable import VisionDocumentScanner

final class QuadrilateralTests: XCTestCase {

    func testQuadrilateralAreaAndCentroid() {
        // 100x100 square
        let quad = Quadrilateral(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: 100, y: 0),
            bottomRight: CGPoint(x: 100, y: 100),
            bottomLeft: CGPoint(x: 0, y: 100)
        )

        XCTAssertEqual(quad.area, 10000.0, accuracy: 0.01)
        XCTAssertEqual(quad.centroid.x, 50.0, accuracy: 0.01)
        XCTAssertEqual(quad.centroid.y, 50.0, accuracy: 0.01)
        XCTAssertEqual(quad.boundingBox, CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertTrue(quad.isConvex)
    }

    func testConvexityDetection() {
        // Convex quadrilateral
        let convexQuad = Quadrilateral(
            topLeft: CGPoint(x: 10, y: 10),
            topRight: CGPoint(x: 90, y: 20),
            bottomRight: CGPoint(x: 80, y: 95),
            bottomLeft: CGPoint(x: 15, y: 85)
        )
        XCTAssertTrue(convexQuad.isConvex)

        // Concave quadrilateral (point pushed inside)
        let concaveQuad = Quadrilateral(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: 100, y: 0),
            bottomRight: CGPoint(x: 40, y: 40), // indent towards center
            bottomLeft: CGPoint(x: 0, y: 100)
        )
        XCTAssertFalse(concaveQuad.isConvex)
    }

    func testScalingAndNormalization() {
        let quad = Quadrilateral(
            topLeft: CGPoint(x: 0.1, y: 0.2),
            topRight: CGPoint(x: 0.9, y: 0.2),
            bottomRight: CGPoint(x: 0.9, y: 0.8),
            bottomLeft: CGPoint(x: 0.1, y: 0.8)
        )

        let size = CGSize(width: 1000, height: 2000)
        let scaled = quad.scaled(to: size)

        XCTAssertEqual(scaled.topLeft.x, 100, accuracy: 0.01)
        XCTAssertEqual(scaled.topLeft.y, 400, accuracy: 0.01)
        XCTAssertEqual(scaled.bottomRight.x, 900, accuracy: 0.01)
        XCTAssertEqual(scaled.bottomRight.y, 1600, accuracy: 0.01)

        let renormalized = scaled.normalized(for: size)
        XCTAssertEqual(renormalized.topLeft.x, quad.topLeft.x, accuracy: 0.001)
        XCTAssertEqual(renormalized.topLeft.y, quad.topLeft.y, accuracy: 0.001)
    }

    func testScrambledPointOrdering() {
        let p1 = CGPoint(x: 10, y: 10)   // TL
        let p2 = CGPoint(x: 200, y: 15)  // TR
        let p3 = CGPoint(x: 195, y: 300) // BR
        let p4 = CGPoint(x: 15, y: 290)  // BL

        // Scramble order: BR, TL, BL, TR
        let scrambled = [p3, p1, p4, p2]
        guard let ordered = Quadrilateral.ordered(from: scrambled) else {
            XCTFail("Failed to order points")
            return
        }

        XCTAssertEqual(ordered.topLeft.x, p1.x, accuracy: 1.0)
        XCTAssertEqual(ordered.topLeft.y, p1.y, accuracy: 1.0)
        XCTAssertEqual(ordered.topRight.x, p2.x, accuracy: 1.0)
        XCTAssertEqual(ordered.topRight.y, p2.y, accuracy: 1.0)
        XCTAssertEqual(ordered.bottomRight.x, p3.x, accuracy: 1.0)
        XCTAssertEqual(ordered.bottomRight.y, p3.y, accuracy: 1.0)
        XCTAssertEqual(ordered.bottomLeft.x, p4.x, accuracy: 1.0)
        XCTAssertEqual(ordered.bottomLeft.y, p4.y, accuracy: 1.0)
    }

    func testStandardInset() {
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 600)
        let inset = Quadrilateral.standardInset(bounds: bounds, percentage: 0.1)

        XCTAssertEqual(inset.topLeft.x, 40, accuracy: 0.01)
        XCTAssertEqual(inset.topLeft.y, 60, accuracy: 0.01)
        XCTAssertEqual(inset.bottomRight.x, 360, accuracy: 0.01)
        XCTAssertEqual(inset.bottomRight.y, 540, accuracy: 0.01)
    }
}
