//
//  Group.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content that adds nothing of its own: a way to apply one modifier to several pieces.
public struct Group: PrintContent {
    let nodes: [PrintNode]

    init(nodes: [PrintNode]) {
        self.nodes = nodes
    }

    /// The content, as one piece.
    public init<Content: PrintContent>(@PrintBuilder content: () -> Content) {
        self.nodes = content()._printNodes().nodes
    }

    public var body: Never {
        return fatalError("Group has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes(nodes)
    }
}
