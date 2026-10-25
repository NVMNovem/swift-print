//
//  ReceiptRow.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// One line of columns: some held to the leading edge, some to the trailing edge.
///
/// One column is flexible and wraps onto continuation lines under itself: the last leading column,
/// or, when nothing leads, the first trailing one. Every other column keeps its natural width — so
/// a product name wraps and its price stays on the first line.
public struct ReceiptRow: Sendable, Hashable {
    public var leading: [[StyledRun]]
    public var trailing: [[StyledRun]]

    public init(leading: [[StyledRun]], trailing: [[StyledRun]] = []) {
        self.leading = leading
        self.trailing = trailing
    }
}
