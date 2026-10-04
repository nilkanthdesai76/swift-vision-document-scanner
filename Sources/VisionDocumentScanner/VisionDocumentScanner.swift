@_exported import Foundation
@_exported import CoreGraphics
@_exported import CoreImage
@_exported import Vision

/// Document Scanner facade providing convenient high-level scanning methods.
public enum VisionDocumentScanner {
    /// Convenience method to detect, crop, and apply filter in a single step.
    public static func scan(
        image: CGImage,
        configuration: DetectionConfiguration = .default,
        filter: ScanFilter = .original
    ) async throws -> (quadrilateral: Quadrilateral, processedImage: CGImage)? {
        let detector = DocumentDetector.shared
        let processor = DocumentProcessor.shared

        let detectedQuad = try await detector.detect(in: image, configuration: configuration, normalized: false)
        let quad = detectedQuad ?? detector.fallback(for: CGSize(width: image.width, height: image.height), configuration: configuration)

        guard let processed = processor.process(image: image, quadrilateral: quad, filter: filter) else {
            return nil
        }

        return (quadrilateral: quad, processedImage: processed)
    }
}
