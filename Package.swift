// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-receipt",
    products: [
        .library(name: "Receipt", targets: ["Receipt"]),
        .library(name: "ReceiptCore", targets: ["ReceiptCore"]),
    ],
    targets: [
        .target(
            name: "Receipt",
        ),
        .testTarget(
            name: "ReceiptTests",
            dependencies: ["Receipt"],
        ),
        .target(
            name: "ReceiptCore",
        ),
        .testTarget(
            name: "ReceiptCoreTests",
            dependencies: ["ReceiptCore"],
        ),
    ]
)
