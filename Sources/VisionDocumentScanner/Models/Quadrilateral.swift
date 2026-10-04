import Foundation
import CoreGraphics

/// Represents a four-sided polygon defining document boundaries in 2D space.
public struct Quadrilateral: Sendable, Hashable, Codable {
    public var topLeft: CGPoint
    public var topRight: CGPoint
    public var bottomRight: CGPoint
    public var bottomLeft: CGPoint

    public init(
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    /// Array of all 4 corners in clockwise order starting from top-left.
    public var corners: [CGPoint] {
        [topLeft, topRight, bottomRight, bottomLeft]
    }

    /// The minimum bounding rectangle enclosing all four corners.
    public var boundingBox: CGRect {
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else {
            return .zero
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// The center of mass (centroid) of the quadrilateral.
    public var centroid: CGPoint {
        let x = corners.reduce(0.0) { $0 + $1.x } / 4.0
        let y = corners.reduce(0.0) { $0 + $1.y } / 4.0
        return CGPoint(x: x, y: y)
    }

    /// The polygonal surface area computed using the Shoelace formula.
    public var area: CGFloat {
        let p = corners
        let sum1 = p[0].x * p[1].y + p[1].x * p[2].y + p[2].x * p[3].y + p[3].x * p[0].y
        let sum2 = p[0].y * p[1].x + p[1].y * p[2].x + p[2].y * p[3].x + p[3].y * p[0].x
        return abs(sum1 - sum2) * 0.5
    }

    /// Checks whether the four points form a strictly convex polygon with positive area.
    public var isConvex: Bool {
        guard area > 0.0001 else { return false }
        let p = corners
        var positive = false
        var negative = false

        for i in 0..<4 {
            let p0 = p[i]
            let p1 = p[(i + 1) % 4]
            let p2 = p[(i + 2) % 4]

            let dx1 = p1.x - p0.x
            let dy1 = p1.y - p0.y
            let dx2 = p2.x - p1.x
            let dy2 = p2.y - p1.y

            let crossProduct = dx1 * dy2 - dy1 * dx2
            if crossProduct > 0 {
                positive = true
            } else if crossProduct < 0 {
                negative = true
            }

            if positive && negative {
                return false
            }
        }
        return true
    }

    /// Scales the quadrilateral coordinates by multiplying by the specified size.
    public func scaled(to size: CGSize) -> Quadrilateral {
        Quadrilateral(
            topLeft: CGPoint(x: topLeft.x * size.width, y: topLeft.y * size.height),
            topRight: CGPoint(x: topRight.x * size.width, y: topRight.y * size.height),
            bottomRight: CGPoint(x: bottomRight.x * size.width, y: bottomRight.y * size.height),
            bottomLeft: CGPoint(x: bottomLeft.x * size.width, y: bottomLeft.y * size.height)
        )
    }

    /// Normalizes the coordinates into unit space [0.0 ... 1.0] by dividing by the specified size.
    public func normalized(for size: CGSize) -> Quadrilateral {
        guard size.width > 0, size.height > 0 else { return self }
        return Quadrilateral(
            topLeft: CGPoint(x: topLeft.x / size.width, y: topLeft.y / size.height),
            topRight: CGPoint(x: topRight.x / size.width, y: topRight.y / size.height),
            bottomRight: CGPoint(x: bottomRight.x / size.width, y: bottomRight.y / size.height),
            bottomLeft: CGPoint(x: bottomLeft.x / size.width, y: bottomLeft.y / size.height)
        )
    }

    /// Inverts Y coordinates to translate between Vision's bottom-left origin and CoreImage/UIKit top-left origin.
    public func flippingY(height: CGFloat = 1.0) -> Quadrilateral {
        Quadrilateral(
            topLeft: CGPoint(x: topLeft.x, y: height - topLeft.y),
            topRight: CGPoint(x: topRight.x, y: height - topRight.y),
            bottomRight: CGPoint(x: bottomRight.x, y: height - bottomRight.y),
            bottomLeft: CGPoint(x: bottomLeft.x, y: height - bottomLeft.y)
        )
    }

    /// Orders an arbitrary array of 4 points into consistent [topLeft, topRight, bottomRight, bottomLeft] order.
    public static func ordered(from points: [CGPoint]) -> Quadrilateral? {
        guard points.count == 4 else { return nil }

        // Divide into top two (smallest y) and bottom two (largest y)
        let sortedByY = points.sorted { $0.y < $1.y }
        let topTwo = Array(sortedByY.prefix(2)).sorted { $0.x < $1.x }
        let bottomTwo = Array(sortedByY.suffix(2)).sorted { $0.x > $1.x }

        return Quadrilateral(
            topLeft: topTwo[0],
            topRight: topTwo[1],
            bottomRight: bottomTwo[0],
            bottomLeft: bottomTwo[1]
        )
    }

    /// Creates a centered quadrilateral inset within the specified bounds by a percentage margin (e.g. 0.08 = 8%).
    public static func standardInset(bounds: CGRect, percentage: CGFloat = 0.08) -> Quadrilateral {
        let dx = bounds.width * percentage
        let dy = bounds.height * percentage
        let inset = bounds.insetBy(dx: dx, dy: dy)
        return Quadrilateral(
            topLeft: CGPoint(x: inset.minX, y: inset.minY),
            topRight: CGPoint(x: inset.maxX, y: inset.minY),
            bottomRight: CGPoint(x: inset.maxX, y: inset.maxY),
            bottomLeft: CGPoint(x: inset.minX, y: inset.maxY)
        )
    }
}
