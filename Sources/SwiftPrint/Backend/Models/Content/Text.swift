//
//  Text.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Text that wraps at the width it has.
///
/// Texts joined with `+` print on one line in their own styles:
/// `Text("Totaal").bold() + Text(" incl. btw")`.
public struct Text: PrintContent {
    var fragments: [TextFragment]
    var alignment: PrintAlignment?

    /// Text that prints `string`. A line break in it always starts a new line.
    public init(_ string: String) {
        self.fragments = [TextFragment(string: string, style: StyleOverride())]
    }

    public var body: Never {
        return fatalError("Text has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.text(fragments, alignment: alignment)])
    }

    /// Both texts on one line, each in its own style.
    public static func + (lhs: Text, rhs: Text) -> Text {
        var text = lhs
        text.fragments += rhs.fragments
        return text
    }

    // MARK: - Modifiers

    /// Bold, for every fragment that has not chosen otherwise.
    public func bold(_ isOn: Bool = true) -> Text {
        styled { $0.isBold = isOn }
    }

    /// Underlined, for every fragment that has not chosen otherwise.
    public func underline(_ isOn: Bool = true) -> Text {
        styled { $0.isUnderlined = isOn }
    }

    /// White on black, for every fragment that has not chosen otherwise.
    public func inverted(_ isOn: Bool = true) -> Text {
        styled { $0.isInverted = isOn }
    }

    /// The magnification of every fragment that has not chosen its own.
    public func size(_ size: TextSize) -> Text {
        styled { $0.size = size }
    }

    /// The printer font of every fragment that has not chosen its own.
    public func font(_ font: PrintFont) -> Text {
        styled { $0.font = font }
    }

    /// Where the text's lines sit across the width, whatever the content around it says.
    public func alignment(_ alignment: PrintAlignment) -> Text {
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
