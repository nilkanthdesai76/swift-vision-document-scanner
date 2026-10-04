import Foundation
import CoreGraphics

/// Configuration options for tuning Apple Vision quadrilateral edge detection.
public struct DetectionConfiguration: Sendable {
    /// Minimum confidence threshold for an observation to be considered valid (0.0 ... 1.0).
    public var minimumConfidence: Float

    /// Minimum acceptable aspect ratio (width / height) of the detected rectangle.
    public var minimumAspectRatio: Float

    /// Maximum acceptable aspect ratio (width / height) of the detected rectangle.
    public var maximumAspectRatio: Float

    /// Minimum dimension of the rectangle relative to the smallest image dimension.
    public var minimumSize: Float

    /// Amount in degrees by which the angles of the detected polygon can deviate from 90 degrees.
    public var quadratureTolerance: Float

    /// Maximum number of rectangle candidates to detect per frame.
    public var maximumObservations: Int

    /// Inset percentage used to generate a fallback quadrilateral if no document is detected.
    public var fallbackInsetPercentage: CGFloat

    public init(
        minimumConfidence: Float = 0.2,
        minimumAspectRatio: Float = 0.2,
        maximumAspectRatio: Float = 1.0,
        minimumSize: Float = 0.15,
        quadratureTolerance: Float = 30.0,
        maximumObservations: Int = 1,
        fallbackInsetPercentage: CGFloat = 0.08
    ) {
        self.minimumConfidence = minimumConfidence
        self.minimumAspectRatio = minimumAspectRatio
        self.maximumAspectRatio = maximumAspectRatio
        self.minimumSize = minimumSize
        self.quadratureTolerance = quadratureTolerance
        self.maximumObservations = maximumObservations
        self.fallbackInsetPercentage = fallbackInsetPercentage
    }

    /// Standard default configuration tuned for typical documents (A4, receipts, letter).
    public static let `default` = DetectionConfiguration()

    /// Lenient configuration allowing more distorted angles and lower contrast edges.
    public static let lenient = DetectionConfiguration(
        minimumConfidence: 0.1,
        minimumAspectRatio: 0.1,
        maximumAspectRatio: 1.0,
        minimumSize: 0.1,
        quadratureTolerance: 45.0
    )
}
