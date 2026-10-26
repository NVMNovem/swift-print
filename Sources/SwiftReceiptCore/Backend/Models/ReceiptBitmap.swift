//
//  ReceiptBitmap.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A 1-bit image ready for a printer: rows of packed bits, most significant bit first, a set bit is
/// a printed dot.
public struct ReceiptBitmap: Sendable, Hashable {
    /// The width in dots.
    public let width: Int
    /// The height in dots.
    public let height: Int
    /// ``bytesPerRow`` bytes for every row, top to bottom.
    public let packedRows: [UInt8]

    /// Bytes per row: the width rounded up to whole bytes.
    public var bytesPerRow: Int {
        (width + 7) / 8
    }

    /// Answers `nil` when the byte count does not match the size.
    public init?(width: Int, height: Int, packedRows: [UInt8]) {
        guard width > 0, height > 0, packedRows.count == (width + 7) / 8 * height else { return nil }
        self.width = width
        self.height = height
        self.packedRows = packedRows
    }

    /// Whether the dot at `x`, `y` is printed.
    public func isDot(x: Int, y: Int) -> Bool {
        packedRows[y * bytesPerRow + x / 8] & (0x80 >> UInt8(x % 8)) != 0
    }
}
