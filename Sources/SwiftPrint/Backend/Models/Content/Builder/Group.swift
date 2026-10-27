//
//  Group.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content that adds nothing of its own: a way to apply one modifier to several pieces.
public struct Group: ReceiptContent {
    let nodes: [ReceiptNode]

    init(nodes: [ReceiptNode]) {
        self.nodes = nodes
    }

    /// The content, as one piece.
    public init<Content: ReceiptContent>(@ReceiptBuilder content: () -> Content) {
        self.nodes = content()._receiptNodes().nodes
    }

    public var body: Never {
        return fatalError("Group has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes(nodes)
    }
}
