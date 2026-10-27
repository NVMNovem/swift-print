//
//  HStack.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// One row of text columns.
///
/// Columns before a ``Spacer`` hold to the leading edge, columns after it to the trailing edge. The
/// column just before the spacer — or the last one, without a spacer — is the one that wraps; the
/// others keep their width. So `HStack { Text(name); Spacer(); Text(price) }` wraps the name and
/// keeps the price on the first line. Only text belongs in a row; anything else is placed after it.
public struct HStack: ReceiptContent {
    let children: [ReceiptNode]

    /// A row of the content's text columns.
    public init<Content: ReceiptContent>(@ReceiptBuilder content: () -> Content) {
        self.children = content()._receiptNodes().nodes
    }

    public var body: Never {
        return fatalError("HStack has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.row(children)])
    }
}
