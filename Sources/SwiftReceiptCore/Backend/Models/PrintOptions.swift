//
//  PrintOptions.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// What is done to the printer around a receipt, and how long each step may take.
public struct PrintOptions: Sendable, Hashable {
    public var paperWidth: ReceiptPaperWidth
    /// `nil` feeds without cutting.
    public var cut: ReceiptCut?
    /// Lines fed after the last line, so it clears the cutter or the tear bar.
    public var feedLines: Int
    public var connectTimeout: Duration
    public var writeTimeout: Duration
    public var statusTimeout: Duration

    public init(
        paperWidth: ReceiptPaperWidth = .millimeters80,
        cut: ReceiptCut? = .partial,
        feedLines: Int = 3,
        connectTimeout: Duration = .seconds(5),
        writeTimeout: Duration = .seconds(10),
        statusTimeout: Duration = .seconds(3)
    ) {
        self.paperWidth = paperWidth
        self.cut = cut
        self.feedLines = feedLines
        self.connectTimeout = connectTimeout
        self.writeTimeout = writeTimeout
        self.statusTimeout = statusTimeout
    }
}
