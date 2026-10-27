//
//  PrintOptions.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// What is done to the printer around a receipt, and how long each step may take.
public struct PrintOptions: Sendable, Hashable {
    /// The paper roll in the printer.
    public var paperWidth: ReceiptPaperWidth
    /// `nil` feeds without cutting.
    public var cut: ReceiptCut?
    /// Lines fed after the last line, so it clears the cutter or the tear bar.
    public var feedLines: Int
    /// How long opening the connection may take.
    public var connectTimeout: Duration
    /// How long sending the receipt may take.
    public var writeTimeout: Duration
    /// How long the printer may take to answer a status request.
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
