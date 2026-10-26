//
//  QRCode.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A QR code drawn by the printer. Left off, and reported, on a printer without QR codes.
public struct QRCode: ReceiptContent {
    let code: ReceiptQRCode

    /// A QR code holding `payload`, `moduleSize` dots per module.
    public init(
        _ payload: String,
        moduleSize: Int = 6,
        errorCorrection: ReceiptQRCode.ErrorCorrection = .medium
    ) {
        self.code = ReceiptQRCode(payload, moduleSize: moduleSize, errorCorrection: errorCorrection)
    }

    public var body: Never {
        return fatalError("QRCode has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.qrCode(code)])
    }
}
