//
//  LabelLayout.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// A label: content placed on a canvas of a fixed size.
///
/// The width and height are the size the label was designed for. Layout converts them to the
/// printer's dots with its resolution, so the same label prints at the same size at 203 and
/// 300 dpi, and places the content one piece under the other, as in a ``VStack``, within them.
///
/// Nothing is clipped, scaled or substituted. A size that is not a size, or that is larger than the
/// printer prints or than the media configured in ``LabelOptions``, is refused before any content
/// is placed; content that does not fit the size is refused with
/// ``PrintError/Reason/contentOverflow(_:)``.
public struct LabelLayout: PrintLayout {
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

    public func _resolved() -> ResolvedDocument {
        ResolvedDocument(format: .label(size), nodes: children)
    }
}
