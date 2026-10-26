//
//  ForEach.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content repeated for every element of a sequence, such as the lines of an order.
public struct ForEach: ReceiptContent {
    let nodes: [ReceiptNode]

    /// The content for every element of `data`, in order.
    public init<Data: Sequence, Content: ReceiptContent>(
        _ data: Data,
        @ReceiptBuilder content: (Data.Element) -> Content
    ) {
        self.nodes = data.flatMap { content($0)._receiptNodes().nodes }
    }

    public var body: Never {
        return fatalError("ForEach has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes(nodes)
    }
}
