//
//  ReceiptLayout.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// Content printed as a receipt: line after line at the paper's width, as long as it needs.
///
/// Content outside any layout already prints as a receipt; this says so explicitly. A layout
/// decides the format only as the outermost content.
public struct ReceiptLayout: PrintContent {
    let children: [PrintNode]

    /// The content as a receipt.
    public init<Content: PrintContent>(@PrintBuilder content: () -> Content) {
        self.children = content()._printNodes().nodes
    }

    public var body: Never {
        return fatalError("ReceiptLayout has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.layout(.receipt, children)])
    }
}
