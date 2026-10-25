//
//  Divider.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A line filled with one character.
public struct Divider: ReceiptContent {
    let character: Character

    public init(_ character: Character = "-") {
        self.character = character
    }

    public var body: Never {
        return fatalError("Divider has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.divider(character)])
    }
}
