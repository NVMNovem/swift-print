//
//  PrintNode.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content after the builder has run, before its styles are resolved into elements.
indirect enum PrintNode: Hashable, Sendable {
    case text([TextFragment], alignment: PrintAlignment?)
    case spacer
    case divider(Character)
    case feed(Int)
    case image(PrintImage)
    case qrCode(PrintQRCode)
    case barcode(PrintBarcode)
    case stack([PrintNode], spacing: PrintLength)
    case row([PrintNode])
    case styled(StyleOverride, alignment: PrintAlignment?, [PrintNode])
    case padding(PrintInsets, [PrintNode])
}

/// A string and the style its own modifiers gave it.
struct TextFragment: Hashable, Sendable {
    var string: String
    var style: StyleOverride
}

/// The nodes of a piece of content. Public only so ``PrintContent`` can name it.
public struct _PrintNodes: Sendable {
    let nodes: [PrintNode]

    init(_ nodes: [PrintNode]) {
        self.nodes = nodes
    }
}
