//
//  ForEach.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content repeated for every element of a sequence, such as the lines of an order.
public struct ForEach: PrintContent {
    let nodes: [PrintNode]

    /// The content for every element of `data`, in order.
    public init<Data: Sequence, Content: PrintContent>(
        _ data: Data,
        @PrintBuilder content: (Data.Element) -> Content
    ) {
        self.nodes = data.flatMap { content($0)._printNodes().nodes }
    }

    public var body: Never {
        return fatalError("ForEach has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes(nodes)
    }
}
