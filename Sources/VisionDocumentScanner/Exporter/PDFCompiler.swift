import Foundation
import CoreGraphics
import PDFKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Page size formatting presets for compiled PDF documents.
public enum PDFPageSizePreset: Sendable, Equatable {
    /// Sizes each PDF page to match the exact pixel dimensions of the source image.
    case matchImageSize

    /// Standard International A4 paper (595.2 x 841.8 points, ~8.27 x 11.69 inches).
    case a4(margin: CGFloat = 20.0)

    /// Standard North American US Letter paper (612.0 x 792.0 points, 8.5 x 11.0 inches).
    case usLetter(margin: CGFloat = 20.0)

    public var dimensions: CGSize? {
        switch self {
        case .matchImageSize:
            return nil
        case .a4:
            return CGSize(width: 595.2, height: 841.8)
        case .usLetter:
            return CGSize(width: 612.0, height: 792.0)
        }
    }
}

/// Metadata embedded in the compiled PDF header.
public struct PDFMetadata: Sendable {
    public var title: String
    public var author: String
    public var subject: String
    public var creator: String

    public init(
        title: String = "Scanned Document",
        author: String = "",
        subject: String = "Document Scan",
        creator: String = "VisionDocumentScanner"
    ) {
        self.title = title
        self.author = author
        self.subject = subject
        self.creator = creator
    }

    public var dictionary: [PDFDocumentAttribute: Any] {
        var dict: [PDFDocumentAttribute: Any] = [
            .titleAttribute: title,
            .subjectAttribute: subject,
            .creatorAttribute: creator,
            .creationDateAttribute: Date()
        ]
        if !author.isEmpty {
            dict[.authorAttribute] = author
        }
        return dict
    }
}

/// Compiles scanned images into multi-page vector-quality PDF documents.
public final class PDFCompiler: @unchecked Sendable {
    public static let shared = PDFCompiler()

    public init() {}

    /// Compiles an array of CGImages into PDF document raw binary data.
    ///
    /// - Parameters:
    ///   - images: Ordered array of page images to compile.
    ///   - pageSize: Paper size preset to use.
    ///   - metadata: Document header metadata.
    /// - Returns: Complete PDF binary data, or nil if compilation failed.
    public func compile(
        images: [CGImage],
        pageSize: PDFPageSizePreset = .matchImageSize,
        metadata: PDFMetadata = .init()
    ) -> Data? {
        guard !images.isEmpty else { return nil }

        let pdfDocument = PDFDocument()
        pdfDocument.documentAttributes = metadata.dictionary

        for (index, cgImage) in images.enumerated() {
            guard let page = makePDFPage(from: cgImage, preset: pageSize) else {
                continue
            }
            pdfDocument.insert(page, at: index)
        }

        guard pdfDocument.pageCount > 0 else { return nil }
        return pdfDocument.dataRepresentation()
    }

    /// Compiles and writes the PDF document directly to disk.
    public func write(
        images: [CGImage],
        to fileURL: URL,
        pageSize: PDFPageSizePreset = .matchImageSize,
        metadata: PDFMetadata = .init()
    ) throws {
        guard let data = compile(images: images, pageSize: pageSize, metadata: metadata) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: fileURL, options: .atomic)
    }

    private func makePDFPage(from cgImage: CGImage, preset: PDFPageSizePreset) -> PDFPage? {
        #if canImport(UIKit)
        let image = UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif

        switch preset {
        case .matchImageSize:
            return PDFPage(image: image)

        case .a4(let margin), .usLetter(let margin):
            guard let targetSize = preset.dimensions else {
                return PDFPage(image: image)
            }

            let printableWidth = targetSize.width - (margin * 2)
            let printableHeight = targetSize.height - (margin * 2)
            let imgWidth = CGFloat(cgImage.width)
            let imgHeight = CGFloat(cgImage.height)

            let scale = min(printableWidth / imgWidth, printableHeight / imgHeight)
            let scaledWidth = imgWidth * scale
            let scaledHeight = imgHeight * scale

            let x = margin + (printableWidth - scaledWidth) / 2.0
            let y = margin + (printableHeight - scaledHeight) / 2.0
            let destRect = CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)

            // Render onto target canvas using CoreGraphics
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: Int(targetSize.width),
                height: Int(targetSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return PDFPage(image: image)
            }

            // White background
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(origin: .zero, size: targetSize))

            // Draw image scaled
            context.draw(cgImage, in: destRect)

            guard let finalCgImage = context.makeImage() else {
                return PDFPage(image: image)
            }

            #if canImport(UIKit)
            let renderedImage = UIImage(cgImage: finalCgImage)
            #elseif canImport(AppKit)
            let renderedImage = NSImage(cgImage: finalCgImage, size: targetSize)
            #endif

            return PDFPage(image: renderedImage)
        }
    }
}
