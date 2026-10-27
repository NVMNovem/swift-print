//
//  ReceiptCapabilities.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// What a driver's printer does beyond bold text, alignment, magnification and line feeds.
///
/// Layout reads these to degrade a receipt by rule — underline to plain, an image left out —
/// instead of sending bytes the printer would misread.
public struct ReceiptCapabilities: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Underlined text.
    public static let underline = ReceiptCapabilities(rawValue: 1 << 0)
    /// White text on a black background.
    public static let inverted = ReceiptCapabilities(rawValue: 1 << 1)
    /// The printer's condensed font, ``ReceiptFont/secondary``.
    public static let secondaryFont = ReceiptCapabilities(rawValue: 1 << 2)
    /// Raster images.
    public static let images = ReceiptCapabilities(rawValue: 1 << 3)
    /// QR codes drawn by the printer.
    public static let qrCodes = ReceiptCapabilities(rawValue: 1 << 4)
    /// A ``ReceiptCut/full`` cut.
    public static let fullCut = ReceiptCapabilities(rawValue: 1 << 5)
    /// A ``ReceiptCut/partial`` cut.
    public static let partialCut = ReceiptCapabilities(rawValue: 1 << 6)
    /// The printer can be asked for its status.
    public static let status = ReceiptCapabilities(rawValue: 1 << 7)
}
