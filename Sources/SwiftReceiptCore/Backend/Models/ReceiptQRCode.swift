//
//  ReceiptQRCode.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A QR code, by meaning. The driver draws it with the printer's own command.
public struct ReceiptQRCode: Sendable, Hashable {
    /// The share of the symbol that may be damaged and still read.
    public enum ErrorCorrection: Sendable, Hashable, CaseIterable {
        case low
        case medium
        case quartile
        case high
    }

    public var payload: String
    /// Dots per module.
    public var moduleSize: Int
    public var errorCorrection: ErrorCorrection

    public init(_ payload: String, moduleSize: Int = 6, errorCorrection: ErrorCorrection = .medium) {
        self.payload = payload
        self.moduleSize = moduleSize
        self.errorCorrection = errorCorrection
    }
}
