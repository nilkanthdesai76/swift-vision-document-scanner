import Foundation
import CoreGraphics

/// Represents a single captured and processed document page.
public struct ScannedPage: Identifiable, Sendable {
    public let id: UUID
    public let originalSize: CGSize
    public var quadrilateral: Quadrilateral
    public var filter: ScanFilter
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        originalSize: CGSize,
        quadrilateral: Quadrilateral,
        filter: ScanFilter = .original,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.originalSize = originalSize
        self.quadrilateral = quadrilateral
        self.filter = filter
        self.timestamp = timestamp
    }
}

/// Represents a multi-page scanned document ready for export.
public struct ScannedDocument: Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var pages: [ScannedPage]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "Scanned Document",
        pages: [ScannedPage] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.pages = pages
        self.createdAt = createdAt
    }
}
