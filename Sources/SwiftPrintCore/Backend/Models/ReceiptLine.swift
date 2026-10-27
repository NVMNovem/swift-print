//
//  ReceiptLine.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// One printed line after layout.
public enum ReceiptLine: Sendable, Hashable {
    /// Runs positioned by padding with plain spaces; the line starts at the leading edge.
    case text([StyledRun])
    /// An empty line.
    case blank
    /// A dithered picture.
    case image(PrintBitmap, alignment: PrintAlignment)
    /// A QR code.
    case qrCode(PrintQRCode, alignment: PrintAlignment)
    /// A barcode.
    case barcode(PrintBarcode, alignment: PrintAlignment)
}
