//
//  ModifiedContent.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content with a style or an alignment applied to everything inside it.
public struct ModifiedContent: ReceiptContent {
    let nodes: [ReceiptNode]
    let override: StyleOverride
    let alignment: ReceiptAlignment?

    init(nodes: [ReceiptNode], override: StyleOverride, alignment: ReceiptAlignment?) {
        self.nodes = nodes
        self.override = override
        self.alignment = alignment
    }

    public var body: Never {
        return fatalError("ModifiedContent has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.styled(override, alignment: alignment, nodes)])
    }
}
