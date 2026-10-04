import Foundation
import CoreGraphics
import CoreImage

/// High-performance CoreImage perspective warp corrector and document filter processor.
public final class DocumentProcessor: @unchecked Sendable {
    public static let shared = DocumentProcessor()

    private let ciContext: CIContext

    public init(ciContext: CIContext? = nil) {
        if let ciContext = ciContext {
            self.ciContext = ciContext
        } else {
            // Prefer GPU-backed CIContext; fall back gracefully to CPU if headless/testing
            let options: [CIContextOption: Any] = [
                .useSoftwareRenderer: false,
                .priorityRequestLow: false
            ]
            self.ciContext = CIContext(options: options)
        }
    }

    /// Crops and corrects the perspective of a document region, then applies the requested post-processing filter.
    ///
    /// - Parameters:
    ///   - image: The source CGImage.
    ///   - quadrilateral: The document boundary in top-left pixel coordinates.
    ///   - filter: The color post-processing filter to apply.
    /// - Returns: The rectified, cropped, and filtered CGImage, or nil if processing failed.
    public func process(
        image: CGImage,
        quadrilateral: Quadrilateral,
        filter: ScanFilter = .original
    ) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let imageHeight = CGFloat(image.height)

        // Convert top-left coordinates to CoreImage's bottom-left coordinate space
        let ciTopLeft = CGPoint(x: quadrilateral.topLeft.x, y: imageHeight - quadrilateral.topLeft.y)
        let ciTopRight = CGPoint(x: quadrilateral.topRight.x, y: imageHeight - quadrilateral.topRight.y)
        let ciBottomRight = CGPoint(x: quadrilateral.bottomRight.x, y: imageHeight - quadrilateral.bottomRight.y)
        let ciBottomLeft = CGPoint(x: quadrilateral.bottomLeft.x, y: imageHeight - quadrilateral.bottomLeft.y)

        guard let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection") else {
            return nil
        }

        perspectiveFilter.setValue(ciImage, forKey: kCIInputImageKey)
        perspectiveFilter.setValue(CIVector(cgPoint: ciTopLeft), forKey: "inputTopLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: ciTopRight), forKey: "inputTopRight")
        perspectiveFilter.setValue(CIVector(cgPoint: ciBottomRight), forKey: "inputBottomRight")
        perspectiveFilter.setValue(CIVector(cgPoint: ciBottomLeft), forKey: "inputBottomLeft")

        guard let correctedImage = perspectiveFilter.outputImage else {
            return nil
        }

        let filteredImage = apply(filter: filter, to: correctedImage)
        return ciContext.createCGImage(filteredImage, from: filteredImage.extent)
    }

    /// Applies the specified color post-processing filter to a CIImage.
    public func apply(filter: ScanFilter, to image: CIImage) -> CIImage {
        switch filter {
        case .original:
            return image

        case .colorEnhanced:
            // Enhance contrast and vibrance while cleaning exposure
            let controls = image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.25,
                kCIInputContrastKey: 1.15,
                kCIInputBrightnessKey: 0.02
            ])
            return controls.applyingFilter("CIExposureAdjust", parameters: [
                kCIInputEVKey: 0.1
            ])

        case .grayscale:
            // High-fidelity monochrome conversion
            return image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputContrastKey: 1.1,
                kCIInputBrightnessKey: 0.0
            ])

        case .blackAndWhite:
            // High contrast text binarization
            let desaturated = image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputContrastKey: 2.2,
                kCIInputBrightnessKey: -0.08
            ])
            return desaturated.applyingFilter("CIColorMonochrome", parameters: [
                kCIInputColorKey: CIColor(red: 0.0, green: 0.0, blue: 0.0),
                kCIInputIntensityKey: 0.0
            ])
        }
    }

    /// Computes the unwarped target dimensions from quadrilateral side lengths.
    public static func estimateTargetSize(quadrilateral: Quadrilateral) -> CGSize {
        let p = quadrilateral
        let topWidth = hypot(p.topRight.x - p.topLeft.x, p.topRight.y - p.topLeft.y)
        let bottomWidth = hypot(p.bottomRight.x - p.bottomLeft.x, p.bottomRight.y - p.bottomLeft.y)
        let leftHeight = hypot(p.bottomLeft.x - p.topLeft.x, p.bottomLeft.y - p.topLeft.y)
        let rightHeight = hypot(p.bottomRight.x - p.topRight.x, p.bottomRight.y - p.topRight.y)

        let targetWidth = max(topWidth, bottomWidth)
        let targetHeight = max(leftHeight, rightHeight)
        return CGSize(width: max(targetWidth, 1.0), height: max(targetHeight, 1.0))
    }
}
