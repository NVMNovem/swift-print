//
//  ReceiptBuilder.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Builds receipt content from statements: content, strings, `if`, `if`/`else`, `switch` and `for`.
@resultBuilder
public enum ReceiptBuilder {
    /// Content as it is.
    public static func buildExpression<Content: ReceiptContent>(_ content: Content) -> Content {
        content
    }

    /// A bare string is a ``Text``.
    public static func buildExpression(_ string: String) -> Text {
        Text(string)
    }

    /// An empty block: nothing.
    public static func buildBlock() -> Group {
        Group(nodes: [])
    }

    /// The statements of a block, in order.
    public static func buildBlock<each Content: ReceiptContent>(_ content: repeat each Content) -> Group {
        var nodes: [ReceiptNode] = []
        for piece in repeat each content {
            nodes += piece._receiptNodes().nodes
        }
        return Group(nodes: nodes)
    }

    /// An `if` without `else`: the content when the condition holds, nothing otherwise.
    public static func buildOptional(_ content: Group?) -> Group {
        content ?? Group(nodes: [])
    }

    /// The first branch of an `if`/`else` or `switch`.
    public static func buildEither(first content: Group) -> Group {
        content
    }

    /// The second branch of an `if`/`else` or `switch`.
    public static func buildEither(second content: Group) -> Group {
        content
    }

    /// The content of every iteration of a `for` loop.
    public static func buildArray(_ content: [Group]) -> Group {
        Group(nodes: content.flatMap(\.nodes))
    }
}
