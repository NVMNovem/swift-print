//
//  ReceiptLayout.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// A receipt: content placed line after line, as long as it needs.
///
/// The layout describes how content flows — wrapping, alignment, spacing — and nothing about the
/// paper. The width it wraps at is the printable width of ``ReceiptOptions/paperWidth`` on the
/// printer it is printed on, so the same receipt prints on 58 mm and 80 mm paper unchanged. Its
/// height is however long the content is. Cutting and feeding are the print job's, in
/// ``ReceiptOptions``.
public struct ReceiptLayout: PrintLayout {
    let children: [PrintNode]

    /// The content as a receipt, one piece under the other.
    public init<Content: PrintContent>(@PrintBuilder content: () -> Content) {
        self.children = content()._printNodes().nodes
    }

    public func _resolved() -> ResolvedDocument {
        ResolvedDocument(format: .receipt, nodes: children)
    }
}
