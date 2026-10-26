//
//  Spacer.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// In an ``HStack``, the point where leading columns end and trailing ones begin. Elsewhere, nothing.
public struct Spacer: ReceiptContent {
    /// The split between leading and trailing columns.
    public init() {}

    public var body: Never {
        return fatalError("Spacer has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.spacer])
    }
}
