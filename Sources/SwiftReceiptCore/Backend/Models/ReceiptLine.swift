//
//  ReceiptLine.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// One printed line after layout.
public enum ReceiptLine: Sendable, Hashable {
    /// Runs positioned by padding with plain spaces; the line starts at the leading edge.
    case text([StyledRun])
    case blank
    case image(ReceiptBitmap, alignment: ReceiptAlignment)
    case qrCode(ReceiptQRCode, alignment: ReceiptAlignment)
}
