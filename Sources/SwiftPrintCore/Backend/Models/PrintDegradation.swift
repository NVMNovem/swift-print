//
//  PrintDegradation.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Something printed differently from how it was written, because the printer cannot do it.
///
/// Receipts degrade by these rules and report them. Labels have no room to reflow, so a label
/// layout refuses instead, with a ``PrintError``.
public enum PrintDegradation: Sendable, Hashable {
    /// A style the printer lacks was left off: underline, inverted or the secondary font.
    case styleUnavailable(PrintCapabilities)
    /// Text was printed at the printer's largest magnification instead.
    case magnificationReduced(requested: TextSize, printed: TextSize)
    /// An image was left out on a printer without images.
    case imageOmitted
    /// A QR code was left out on a printer without QR codes.
    case qrCodeOmitted
    /// A barcode was left out on a printer without barcodes.
    case barcodeOmitted
    /// Padding was left off: a receipt is placed line by line at the paper's width.
    case paddingIgnored
    /// The fixed columns of a row did not leave room for the flexible one; the row was printed as
    /// wrapped text instead.
    case rowOverflow
    /// The printer's character set does not hold the character.
    case characterReplaced(Character, with: String)
    /// The requested cut is not available; the paper was fed instead.
    case cutUnavailable(ReceiptCut)
}
