// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-vision-document-scanner",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "VisionDocumentScanner",
            targets: ["VisionDocumentScanner"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VisionDocumentScanner",
            dependencies: []
        ),
        .testTarget(
            name: "VisionDocumentScannerTests",
            dependencies: ["VisionDocumentScanner"]
        ),
    ]
)
