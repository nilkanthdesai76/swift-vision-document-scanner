import Foundation

/// Post-processing color filter applied to the scanned document image.
public enum ScanFilter: String, CaseIterable, Sendable, Codable {
    /// Preserves original image colors without any color adjustments.
    case original

    /// Boosts contrast and saturation while evening exposure for colorful documents and photos.
    case colorEnhanced

    /// Converts document to clean grayscale tone curve, removing yellowing and color casts.
    case grayscale

    /// Converts document to high-contrast black-and-white, optimizing ink readability and reducing file size.
    case blackAndWhite

    /// Human-readable title for UI presentation.
    public var localizedTitle: String {
        switch self {
        case .original:
            return "Original"
        case .colorEnhanced:
            return "Enhanced Color"
        case .grayscale:
            return "Grayscale"
        case .blackAndWhite:
            return "Black & White"
        }
    }
}
