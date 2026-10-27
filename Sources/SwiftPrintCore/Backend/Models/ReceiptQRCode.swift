//
//  ReceiptQRCode.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A QR code, by meaning. The driver draws it with the printer's own command.
public struct ReceiptQRCode: Sendable, Hashable {
    /// The share of the symbol that may be damaged and still read.
    public enum ErrorCorrection: Sendable, Hashable, CaseIterable {
        /// About 7 %.
        case low
        /// About 15 %.
        case medium
        /// About 25 %.
        case quartile
        /// About 30 %.
        case high
    }

    /// The text the code holds, such as a URL.
    public var payload: String
    /// Dots per module.
    public var moduleSize: Int
    /// How much damage the code survives.
    public var errorCorrection: ErrorCorrection

    public init(_ payload: String, moduleSize: Int = 6, errorCorrection: ErrorCorrection = .medium) {
        self.payload = payload
        self.moduleSize = moduleSize
        self.errorCorrection = errorCorrection
    }
}
