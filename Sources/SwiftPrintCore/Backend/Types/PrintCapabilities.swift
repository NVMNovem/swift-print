//
//  PrintCapabilities.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// What a driver's printer does beyond bold text, alignment, magnification and line feeds.
///
/// Layout reads these to degrade a receipt by rule — underline to plain, an image left out — or to
/// refuse a label, instead of sending bytes the printer would misread.
public struct PrintCapabilities: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Underlined text.
    public static let underline = PrintCapabilities(rawValue: 1 << 0)
    /// White text on a black background.
    public static let inverted = PrintCapabilities(rawValue: 1 << 1)
    /// The printer's condensed font, ``PrintFont/secondary``.
    public static let secondaryFont = PrintCapabilities(rawValue: 1 << 2)
    /// Raster images.
    public static let images = PrintCapabilities(rawValue: 1 << 3)
    /// QR codes drawn by the printer.
    public static let qrCodes = PrintCapabilities(rawValue: 1 << 4)
    /// A ``ReceiptCut/full`` cut.
    public static let fullCut = PrintCapabilities(rawValue: 1 << 5)
    /// A ``ReceiptCut/partial`` cut.
    public static let partialCut = PrintCapabilities(rawValue: 1 << 6)
    /// The printer can be asked for its status, over a transport that reads.
    public static let status = PrintCapabilities(rawValue: 1 << 7)
    /// Linear barcodes drawn by the printer.
    public static let barcodes = PrintCapabilities(rawValue: 1 << 8)
}
