//
//  ReceiptTextSize.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How many times wider and taller than the font's cell text is printed.
///
/// A driver states the largest factor its printer takes; layout prints anything larger at that
/// maximum and reports it.
public struct ReceiptTextSize: Sendable, Hashable {
    /// The horizontal magnification, at least 1.
    public var width: Int
    /// The vertical magnification, at least 1.
    public var height: Int

    /// A size with these factors; anything below 1 is taken as 1.
    public init(width: Int = 1, height: Int = 1) {
        self.width = max(1, width)
        self.height = max(1, height)
    }

    /// The font's own size.
    public static let normal = ReceiptTextSize()
    /// Twice as wide.
    public static let doubleWidth = ReceiptTextSize(width: 2)
    /// Twice as tall.
    public static let doubleHeight = ReceiptTextSize(height: 2)
    /// Twice as wide and twice as tall.
    public static let double = ReceiptTextSize(width: 2, height: 2)
}
