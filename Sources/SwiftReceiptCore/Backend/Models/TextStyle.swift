//
//  TextStyle.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How a run of text is printed.
public struct TextStyle: Sendable, Hashable {
    /// Whether the text is bold.
    public var isBold: Bool
    /// Whether the text is underlined.
    public var isUnderlined: Bool
    /// Whether the text is white on black.
    public var isInverted: Bool
    /// The magnification.
    public var size: ReceiptTextSize
    /// The printer font.
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
