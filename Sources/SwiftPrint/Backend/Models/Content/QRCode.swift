//
//  QRCode.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A QR code drawn by the printer. Left off, and reported, on a receipt printer without QR codes;
/// refused on a label printer without them.
public struct QRCode: PrintContent {
    let code: PrintQRCode

    /// A QR code holding `payload`, `moduleSize` dots per module.
    public init(
        _ payload: String,
        moduleSize: Int = 6,
        errorCorrection: PrintQRCode.ErrorCorrection = .medium
    ) {
        self.code = PrintQRCode(payload, moduleSize: moduleSize, errorCorrection: errorCorrection)
    }

    public var body: Never {
        return fatalError("QRCode has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.qrCode(code)])
    }
}
