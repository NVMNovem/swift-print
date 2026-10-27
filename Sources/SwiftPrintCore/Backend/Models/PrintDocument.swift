//
//  PrintDocument.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// What is printed, independent of any printer: the content, and the layout it is placed with.
///
/// It says what is on the paper and how it should look. It never contains a cut, a drawer kick or
/// a beep: those are things done to a printer, chosen with ``PrintOptions``.
public struct PrintDocument: Sendable, Hashable {
    /// How the content is placed.
    public enum Format: Sendable, Hashable {
        /// Line after line at the paper's width, as long as the content needs; see
        /// ``ReceiptLayoutEngine``.
        case receipt
        /// Positioned within a label of a fixed size; see ``LabelLayoutEngine``.
        case label(LabelSize)
    }

    /// How the content is placed.
    public var format: Format
    /// The content, top to bottom.
    public var content: [PrintElement]

    public init(format: Format = .receipt, content: [PrintElement]) {
        self.format = format
        self.content = content
    }
}

/// The size of a label, edge to edge.
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
