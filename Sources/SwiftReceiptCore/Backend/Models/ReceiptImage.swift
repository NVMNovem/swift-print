//
//  ReceiptImage.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// An image as 8-bit grayscale pixels, row by row: 0 is black, 255 is white.
///
/// The framework decodes no file format. Whoever has the picture turns it into pixels; layout
/// scales and dithers them to the paper.
public struct ReceiptImage: Sendable, Hashable {
    /// The width in pixels.
    public let width: Int
    /// The height in pixels.
    public let height: Int
    /// `width × height` gray levels, row by row.
    public let pixels: [UInt8]

    /// Answers `nil` when the pixel count does not match the size.
    public init?(width: Int, height: Int, pixels: [UInt8]) {
        guard width > 0, height > 0, pixels.count == width * height else { return nil }
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}
