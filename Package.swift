// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-receipt",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "SwiftReceipt", targets: ["SwiftReceipt"]),
        .library(name: "SwiftReceiptCore", targets: ["SwiftReceiptCore"]),
        .library(name: "SwiftReceiptTesting", targets: ["SwiftReceiptTesting"]),
    ],
    traits: [
        .default(enabledTraits: []),
        .trait(name: "ESCPOS", description: "The ESC/POS driver, through swift-escpos."),
    ],
    dependencies: [
        // A branch until swift-escpos is tagged; a tagged swift-receipt needs a version here.
        .package(url: "https://github.com/NVMNovem/swift-escpos.git", branch: "main"),
    ],
    targets: [
        .target(name: "SwiftReceiptCore"),
        .target(
            name: "SwiftReceipt",
            dependencies: [
                "SwiftReceiptCore",
                .product(name: "SwiftESCPOS", package: "swift-escpos", condition: .when(traits: ["ESCPOS"])),
            ]
        ),
        .target(
            name: "SwiftReceiptTesting",
            dependencies: ["SwiftReceiptCore"]
        ),
        .testTarget(
            name: "SwiftReceiptCoreTests",
            dependencies: ["SwiftReceiptCore"]
        ),
        .testTarget(
            name: "SwiftReceiptTests",
            dependencies: [
                "SwiftReceipt",
                "SwiftReceiptTesting",
                .product(name: "SwiftESCPOS", package: "swift-escpos", condition: .when(traits: ["ESCPOS"])),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
