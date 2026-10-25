//
//  TextStyle.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How a run of text is printed.
public struct TextStyle: Sendable, Hashable {
    public var isBold: Bool
    public var isUnderlined: Bool
    public var isInverted: Bool
    public var size: ReceiptTextSize
    public var font: ReceiptFont

    public init(
        isBold: Bool = false,
        isUnderlined: Bool = false,
        isInverted: Bool = false,
        size: ReceiptTextSize = .normal,
        font: ReceiptFont = .primary
    ) {
        self.isBold = isBold
        self.isUnderlined = isUnderlined
        self.isInverted = isInverted
        self.size = size
        self.font = font
    }

    /// What a printer starts with.
    public static let plain = TextStyle()
}
