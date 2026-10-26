//
//  Feed.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Empty lines.
public struct Feed: ReceiptContent {
    let lines: Int

    /// `lines` empty lines; a negative count is none.
    public init(_ lines: Int = 1) {
        self.lines = max(0, lines)
    }

    public var body: Never {
        return fatalError("Feed has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.feed(lines)])
    }
}
