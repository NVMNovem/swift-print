//
//  StyleOverride.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Style set by a modifier; `nil` leaves a field to the content around it.
struct StyleOverride: Hashable, Sendable {
    var isBold: Bool?
    var isUnderlined: Bool?
    var isInverted: Bool?
    var size: ReceiptTextSize?
    var font: ReceiptFont?

    /// This override where it says something, `outer` where it does not: the inner modifier wins.
    func filling(from outer: StyleOverride) -> StyleOverride {
        StyleOverride(
            isBold: isBold ?? outer.isBold,
            isUnderlined: isUnderlined ?? outer.isUnderlined,
            isInverted: isInverted ?? outer.isInverted,
            size: size ?? outer.size,
            font: font ?? outer.font
        )
    }

    var resolved: TextStyle {
        TextStyle(
            isBold: isBold ?? false,
            isUnderlined: isUnderlined ?? false,
            isInverted: isInverted ?? false,
            size: size ?? .normal,
            font: font ?? .primary
        )
    }
}
