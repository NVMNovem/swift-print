//
//  PrintOptions.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// What is done to the paper around a receipt. A label's size is part of its document instead.
public struct PrintOptions: Sendable, Hashable {
    /// The paper roll in the printer.
    public var paperWidth: ReceiptPaperWidth
    /// `nil` feeds without cutting.
    public var cut: ReceiptCut?
    /// Lines fed after the last line, so it clears the cutter or the tear bar.
    public var feedLines: Int

    public init(
        paperWidth: ReceiptPaperWidth = .millimeters80,
        cut: ReceiptCut? = .partial,
        feedLines: Int = 3
    ) {
        self.paperWidth = paperWidth
        self.cut = cut
        self.feedLines = feedLines
    }
}
