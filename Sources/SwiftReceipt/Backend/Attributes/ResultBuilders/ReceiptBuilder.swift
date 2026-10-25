//
//  ReceiptBuilder.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Builds receipt content from statements: content, strings, `if`, `if`/`else`, `switch` and `for`.
@resultBuilder
public enum ReceiptBuilder {
    public static func buildExpression<Content: ReceiptContent>(_ content: Content) -> Content {
        content
    }

    /// A bare string is a ``Text``.
    public static func buildExpression(_ string: String) -> Text {
        Text(string)
    }

    public static func buildBlock() -> Group {
        Group(nodes: [])
    }

    public static func buildBlock<each Content: ReceiptContent>(_ content: repeat each Content) -> Group {
        var nodes: [ReceiptNode] = []
        for piece in repeat each content {
            nodes += piece._receiptNodes().nodes
        }
        return Group(nodes: nodes)
    }

    public static func buildOptional(_ content: Group?) -> Group {
        content ?? Group(nodes: [])
    }

    public static func buildEither(first content: Group) -> Group {
        content
    }

    public static func buildEither(second content: Group) -> Group {
        content
    }

    public static func buildArray(_ content: [Group]) -> Group {
        Group(nodes: content.flatMap(\.nodes))
    }
}
