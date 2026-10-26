//
//  VStack.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content placed line after line, with `spacing` empty lines between pieces.
public struct VStack: ReceiptContent {
    let children: [ReceiptNode]
    let spacing: Int

    /// The content line after line, `spacing` empty lines apart.
    public init<Content: ReceiptContent>(spacing: Int = 0, @ReceiptBuilder content: () -> Content) {
        self.children = content()._receiptNodes().nodes
        self.spacing = max(0, spacing)
    }

    public var body: Never {
        return fatalError("VStack has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.stack(children, spacing: spacing)])
    }
}
