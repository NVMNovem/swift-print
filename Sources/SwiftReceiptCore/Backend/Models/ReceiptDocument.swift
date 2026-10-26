//
//  ReceiptDocument.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A receipt's content, independent of any printer.
///
/// It says what is on the receipt and how it should look. It never contains a cut, a drawer kick or
/// a beep: those are things done to a printer, chosen with ``PrintOptions``.
public struct ReceiptDocument: Sendable, Hashable {
    /// The receipt's pieces, top to bottom.
    public var blocks: [ReceiptBlock]

    public init(blocks: [ReceiptBlock]) {
        self.blocks = blocks
    }
}
