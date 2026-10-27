//
//  ModifiedContent.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content with a style, an alignment or padding applied to everything inside it.
public struct ModifiedContent: PrintContent {
    let node: PrintNode

    init(nodes: [PrintNode], override: StyleOverride, alignment: PrintAlignment?) {
        self.node = .styled(override, alignment: alignment, nodes)
    }

    init(node: PrintNode) {
        self.node = node
    }

    public var body: Never {
        return fatalError("ModifiedContent has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([node])
    }
}
