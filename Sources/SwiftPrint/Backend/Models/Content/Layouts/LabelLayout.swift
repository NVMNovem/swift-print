//
//  LabelLayout.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// Content printed as a label of a fixed size.
///
/// The content is placed one piece under the other within the label, as in a ``VStack``, and must
/// fit: content that is too tall or too wide is refused with
/// ``PrintError/Reason/contentOverflow(_:)`` rather than cut off. Lengths are converted to the
/// printer's dots with its resolution, so the same label prints at the same size at 203 and 300 dpi.
///
/// A layout decides the format only as the outermost content; inside other content it adds its
/// content and nothing else.
public struct LabelLayout: PrintContent {
    let size: LabelSize
    let children: [PrintNode]

    /// A label `width` across the printhead and `height` along the paper.
    public init<Content: PrintContent>(
        width: PrintLength,
        height: PrintLength,
        @PrintBuilder content: () -> Content
    ) {
        self.size = LabelSize(width: width, height: height)
        self.children = content()._printNodes().nodes
    }

    public var body: Never {
        return fatalError("LabelLayout has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.layout(.label(size), children)])
    }
}
