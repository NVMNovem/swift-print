//
//  ReceiptBlock.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// One piece of a receipt, by meaning. Never a printer command.
public enum ReceiptBlock: Sendable, Hashable {
    /// Text that wraps at the paper's width.
    case text([StyledRun], alignment: ReceiptAlignment)
    /// Columns on one line; see ``ReceiptRow``.
    case row(ReceiptRow)
    /// A line filled with one character.
    case divider(Character, style: TextStyle)
    /// Empty lines.
    case spacing(lines: Int)
    /// A picture, scaled and dithered to the paper.
    case image(ReceiptImage, alignment: ReceiptAlignment)
    /// A QR code drawn by the printer.
    case qrCode(ReceiptQRCode, alignment: ReceiptAlignment)
}
