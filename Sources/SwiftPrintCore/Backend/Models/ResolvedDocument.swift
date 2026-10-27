//
//  ResolvedDocument.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A document as the layouts take it: its format and its content, with every style and alignment
/// resolved. Independent of any printer.
///
/// It says what is printed and how it should look. It never contains a cut, a feed, a drawer kick
/// or a beep: those are things done to a printer, chosen with ``PrintOptions``. `SwiftPrint` builds
/// one from a document's root layout; build one directly to work without the declarative content.
public struct ResolvedDocument: Sendable, Hashable {
    /// How the content is placed: the layout the document declared.
    public enum Format: Sendable, Hashable {
        /// Line after line at the printable width of the paper in the printer, as long as the
        /// content needs; see ``ReceiptLayoutEngine``.
        case receipt
        /// Positioned within a label of a fixed size; see ``LabelLayoutEngine``.
        case label(LabelSize)

        /// The layout, without its size.
        public var kind: PrintLayoutKind {
            switch self {
            case .receipt: .receipt
            case .label: .label
            }
        }
    }

    /// How the content is placed.
    public var format: Format
    /// The content, top to bottom.
    public var content: [PrintElement]

    public init(format: Format, content: [PrintElement]) {
        self.format = format
        self.content = content
    }
}

/// A layout, by kind: what a driver prints, and what a ``PrintError`` names when it does not.
public enum PrintLayoutKind: Sendable, Hashable, CaseIterable {
    /// A receipt: a variable height at the paper's width.
    case receipt
    /// A label: a fixed width and height.
    case label
}

/// The size a label was designed for, edge to edge.
///
/// This is the document's size, not the media's: the label stock in the printer is configured with
/// ``LabelOptions/media``, and layout refuses a document that does not fit it.
public struct LabelSize: Sendable, Hashable {
    /// The width, across the printhead.
    public var width: PrintLength
    /// The height, along the paper.
    public var height: PrintLength

    public init(width: PrintLength, height: PrintLength) {
        self.width = width
        self.height = height
    }
}

/// One of a label's two dimensions, as a ``PrintError`` names it.
public enum PrintDimension: Sendable, Hashable, CaseIterable {
    /// Across the printhead.
    case width
    /// Along the paper.
    case height
}
