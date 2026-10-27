//
//  HStack.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content side by side, one plain space apart.
///
/// Pieces before a ``Spacer`` hold to the leading edge, pieces after it to the trailing edge. When
/// they do not fit, the piece just before the spacer — or the last one, without a spacer — is the
/// one that wraps; the others keep their width. So `HStack { Text(name); Spacer(); Text(price) }`
/// wraps the name and keeps the price on the first line.
///
/// On a receipt a row holds text only; anything else is placed after it. On a label any content
/// can sit side by side, such as a QR code next to its text.
public struct HStack: PrintContent {
    let children: [PrintNode]

    /// The content side by side.
    public init<Content: PrintContent>(@PrintBuilder content: () -> Content) {
        self.children = content()._printNodes().nodes
    }

    public var body: Never {
        return fatalError("HStack has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.row(children)])
    }
}
