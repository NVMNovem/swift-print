//
//  ReceiptDegradation.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Something printed differently from how it was written, because the printer cannot do it.
public enum ReceiptDegradation: Sendable, Hashable {
    /// A style the printer lacks was left off: underline, inverted or the secondary font.
    case styleUnavailable(ReceiptCapabilities)
    case magnificationReduced(requested: ReceiptTextSize, printed: ReceiptTextSize)
    case imageOmitted
    case qrCodeOmitted
    /// The fixed columns of a row did not leave room for the flexible one; the row was printed as
    /// wrapped text instead.
    case rowOverflow
    /// The printer's character set does not hold the character.
    case characterReplaced(Character, with: String)
    /// The requested cut is not available; the paper was fed instead.
    case cutUnavailable(ReceiptCut)
}
