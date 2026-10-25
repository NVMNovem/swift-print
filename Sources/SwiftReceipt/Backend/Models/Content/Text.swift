//
//  Text.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Text that wraps at the paper's width.
///
/// Texts joined with `+` print on one line in their own styles:
/// `Text("Totaal").bold() + Text(" incl. btw")`.
public struct Text: ReceiptContent {
    var fragments: [TextFragment]
    var alignment: ReceiptAlignment?

    public init(_ string: String) {
        self.fragments = [TextFragment(string: string, style: StyleOverride())]
    }

    public var body: Never {
        return fatalError("Text has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.text(fragments, alignment: alignment)])
    }

    public static func + (lhs: Text, rhs: Text) -> Text {
        var text = lhs
        text.fragments += rhs.fragments
        return text
    }

    // MARK: - Modifiers

    public func bold(_ isOn: Bool = true) -> Text {
        styled { $0.isBold = isOn }
    }

    public func underline(_ isOn: Bool = true) -> Text {
        styled { $0.isUnderlined = isOn }
    }

    public func inverted(_ isOn: Bool = true) -> Text {
        styled { $0.isInverted = isOn }
    }

    public func size(_ size: ReceiptTextSize) -> Text {
        styled { $0.size = size }
    }

    public func font(_ font: ReceiptFont) -> Text {
        styled { $0.font = font }
    }

    public func alignment(_ alignment: ReceiptAlignment) -> Text {
        var text = self
        text.alignment = alignment
        return text
    }

    /// Applies a style to every fragment that has not set it itself.
    private func styled(_ change: (inout StyleOverride) -> Void) -> Text {
        var override = StyleOverride()
        change(&override)
        var text = self
        text.fragments = fragments.map { TextFragment(string: $0.string, style: $0.style.filling(from: override)) }
        return text
    }
}
