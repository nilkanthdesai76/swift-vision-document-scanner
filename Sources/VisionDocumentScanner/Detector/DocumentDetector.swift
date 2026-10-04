import Foundation
import CoreGraphics
import CoreImage
import Vision

/// Actor-isolated or Sendable Vision rectangle detector for document scanning.
public final class DocumentDetector: @unchecked Sendable {
    public static let shared = DocumentDetector()

    public init() {}

    /// Detects the most prominent document quadrilateral in the given CGImage.
    ///
    /// - Parameters:
    ///   - image: The input CGImage to analyze.
    ///   - configuration: Configuration options tuning the detection thresholds.
    ///   - normalized: If true, returns coordinates in [0...1] unit space with top-left origin.
    ///                 If false, returns coordinates in pixel space.
    /// - Returns: The detected Quadrilateral, or nil if no valid document was found.
    public func detect(
        in image: CGImage,
        configuration: DetectionConfiguration = .default,
        normalized: Bool = false
    ) async throws -> Quadrilateral? {
        let size = CGSize(width: image.width, height: image.height)
        guard size.width > 0, size.height > 0 else { return nil }

        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = configuration.minimumConfidence
        request.minimumAspectRatio = configuration.minimumAspectRatio
        request.maximumAspectRatio = configuration.maximumAspectRatio
        request.minimumSize = configuration.minimumSize
        request.quadratureTolerance = configuration.quadratureTolerance
        request.maximumObservations = configuration.maximumObservations

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            return nil
        }

        // Vision normalized coordinates have (0,0) at bottom-left.
        // Convert to standard top-left origin coordinates.
        let rawQuad = Quadrilateral(
            topLeft: CGPoint(x: observation.topLeft.x, y: 1.0 - observation.topLeft.y),
            topRight: CGPoint(x: observation.topRight.x, y: 1.0 - observation.topRight.y),
            bottomRight: CGPoint(x: observation.bottomRight.x, y: 1.0 - observation.bottomRight.y),
            bottomLeft: CGPoint(x: observation.bottomLeft.x, y: 1.0 - observation.bottomLeft.y)
        )

        guard rawQuad.isConvex else { return nil }

        if normalized {
            return rawQuad
        } else {
            return rawQuad.scaled(to: size)
        }
    }

    /// Detects all document rectangle candidates in the given CGImage.
    public func detectAll(
        in image: CGImage,
        configuration: DetectionConfiguration = .default,
        normalized: Bool = false
    ) async throws -> [Quadrilateral] {
        let size = CGSize(width: image.width, height: image.height)
        guard size.width > 0, size.height > 0 else { return [] }

        var config = configuration
        config.maximumObservations = max(config.maximumObservations, 5)

        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = config.minimumConfidence
        request.minimumAspectRatio = config.minimumAspectRatio
        request.maximumAspectRatio = config.maximumAspectRatio
        request.minimumSize = config.minimumSize
        request.quadratureTolerance = config.quadratureTolerance
        request.maximumObservations = config.maximumObservations

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            return []
        }

        return observations.compactMap { obs in
            let quad = Quadrilateral(
                topLeft: CGPoint(x: obs.topLeft.x, y: 1.0 - obs.topLeft.y),
                topRight: CGPoint(x: obs.topRight.x, y: 1.0 - obs.topRight.y),
                bottomRight: CGPoint(x: obs.bottomRight.x, y: 1.0 - obs.bottomRight.y),
                bottomLeft: CGPoint(x: obs.bottomLeft.x, y: 1.0 - obs.bottomLeft.y)
            )
            guard quad.isConvex else { return nil }
            return normalized ? quad : quad.scaled(to: size)
        }
    }

    /// Returns a fallback quadrilateral inset from the image boundaries when detection fails.
    public func fallback(
        for size: CGSize,
        configuration: DetectionConfiguration = .default
    ) -> Quadrilateral {
        let bounds = CGRect(origin: .zero, size: size)
        return Quadrilateral.standardInset(bounds: bounds, percentage: configuration.fallbackInsetPercentage)
    }
}
