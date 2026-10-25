//
//  ReceiptTextSize.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How many times wider and taller than the font's cell text is printed.
///
/// A driver states the largest factor its printer takes; layout prints anything larger at that
/// maximum and reports it.
public struct ReceiptTextSize: Sendable, Hashable {
    public var width: Int
    public var height: Int

    public init(width: Int = 1, height: Int = 1) {
        self.width = max(1, width)
        self.height = max(1, height)
    }

    public static let normal = ReceiptTextSize()
    public static let doubleWidth = ReceiptTextSize(width: 2)
    public static let doubleHeight = ReceiptTextSize(height: 2)
    public static let double = ReceiptTextSize(width: 2, height: 2)
}
