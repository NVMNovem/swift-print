// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-print",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "SwiftPrint", targets: ["SwiftPrint"]),
        .library(name: "SwiftPrintCore", targets: ["SwiftPrintCore"]),
        .library(name: "SwiftPrintESCPOS", targets: ["SwiftPrintESCPOS"]),
        .library(name: "SwiftPrintZPL", targets: ["SwiftPrintZPL"]),
        .library(name: "SwiftPrintTesting", targets: ["SwiftPrintTesting"]),
    ],
    dependencies: [
        // Branches until swift-escpos and swift-zpl are tagged; a tagged swift-print needs versions here.
        .package(url: "https://github.com/NVMNovem/swift-escpos.git", branch: "main"),
        .package(url: "https://github.com/NVMNovem/swift-zpl.git", branch: "main"),
    ],
    targets: [
        // The document model, both layouts and the driver protocols: no dependencies, no I/O.
        .target(name: "SwiftPrintCore"),
        // The declarative content and `Printer`.
        .target(
            name: "SwiftPrint",
            dependencies: ["SwiftPrintCore"]
        ),
        // Protocol adapters. Only the encoding libraries; their network modules stay the app's choice.
        .target(
            name: "SwiftPrintESCPOS",
            dependencies: [
                "SwiftPrintCore",
                .product(name: "SwiftESCPOS", package: "swift-escpos"),
            ]
        ),
        .target(
            name: "SwiftPrintZPL",
            dependencies: [
                "SwiftPrintCore",
                .product(name: "SwiftZPL", package: "swift-zpl"),
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
                "SwiftPrintCore",
                "SwiftPrintTesting",
            ]
        ),
        .testTarget(
            name: "SwiftPrintESCPOSTests",
            dependencies: [
                "SwiftPrint",
                "SwiftPrintESCPOS",
                .product(name: "SwiftESCPOS", package: "swift-escpos"),
            ]
        ),
        .testTarget(
            name: "SwiftPrintZPLTests",
            dependencies: [
                "SwiftPrint",
                "SwiftPrintZPL",
                .product(name: "SwiftZPL", package: "swift-zpl"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
