//
//  RenderedReceipt.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A receipt as the bytes one driver would send, with everything printed differently.
public struct RenderedReceipt: Sendable, Hashable {
    public var bytes: [UInt8]
    public var degradations: [ReceiptDegradation]

    public init(bytes: [UInt8], degradations: [ReceiptDegradation] = []) {
        self.bytes = bytes
        self.degradations = degradations
    }
}
