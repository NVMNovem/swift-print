// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-print",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "SwiftPrint", targets: ["SwiftPrint"]),
        .library(name: "SwiftPrintCore", targets: ["SwiftPrintCore"]),
        .library(name: "SwiftPrintTesting", targets: ["SwiftPrintTesting"]),
    ],
    traits: [
        .default(enabledTraits: []),
        .trait(name: "ESCPOS", description: "The ESC/POS driver, through swift-escpos."),
    ],
    dependencies: [
        // A branch until swift-escpos is tagged; a tagged swift-print needs a version here.
        .package(url: "https://github.com/NVMNovem/swift-escpos.git", branch: "main"),
    ],
    targets: [
        .target(name: "SwiftPrintCore"),
        .target(
            name: "SwiftPrint",
            dependencies: [
                "SwiftPrintCore",
                .product(name: "SwiftESCPOS", package: "swift-escpos", condition: .when(traits: ["ESCPOS"])),
            ]
        ),
        .target(
            name: "SwiftPrintTesting",
            dependencies: ["SwiftPrintCore"]
        ),
        .testTarget(
            name: "SwiftPrintCoreTests",
            dependencies: ["SwiftPrintCore"]
        ),
        .testTarget(
            name: "SwiftPrintTests",
            dependencies: [
                "SwiftPrint",
                "SwiftPrintTesting",
                .product(name: "SwiftESCPOS", package: "swift-escpos", condition: .when(traits: ["ESCPOS"])),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
