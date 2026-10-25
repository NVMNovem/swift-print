//
//  ReceiptNode.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content after the builder has run, before it becomes blocks.
indirect enum ReceiptNode: Hashable, Sendable {
    case text([TextFragment], alignment: ReceiptAlignment?)
    case spacer
    case divider(Character)
    case feed(Int)
    case image(ReceiptImage)
    case qrCode(ReceiptQRCode)
    case stack([ReceiptNode], spacing: Int)
    case row([ReceiptNode])
    case styled(StyleOverride, alignment: ReceiptAlignment?, [ReceiptNode])
}

/// A string and the style its own modifiers gave it.
struct TextFragment: Hashable, Sendable {
    var string: String
    var style: StyleOverride
}

/// The nodes of a piece of content. Public only so ``ReceiptContent`` can name it.
public struct _ReceiptNodes: Sendable {
    let nodes: [ReceiptNode]

    init(_ nodes: [ReceiptNode]) {
        self.nodes = nodes
    }
}
