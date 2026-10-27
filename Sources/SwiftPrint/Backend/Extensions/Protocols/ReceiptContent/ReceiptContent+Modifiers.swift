//
//  ReceiptContent+Modifiers.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

extension ReceiptContent {
    /// Bold for all text inside that has not chosen otherwise.
    public func bold(_ isOn: Bool = true) -> ModifiedContent {
        modified { $0.isBold = isOn }
    }

    /// Underline for all text inside that has not chosen otherwise.
    public func underline(_ isOn: Bool = true) -> ModifiedContent {
        modified { $0.isUnderlined = isOn }
    }

    /// White on black for all text inside that has not chosen otherwise.
    public func inverted(_ isOn: Bool = true) -> ModifiedContent {
        modified { $0.isInverted = isOn }
    }

    /// The magnification of all text inside that has not chosen its own.
    public func size(_ size: ReceiptTextSize) -> ModifiedContent {
        modified { $0.size = size }
    }

    /// The printer font of all text inside that has not chosen its own.
    public func font(_ font: ReceiptFont) -> ModifiedContent {
        modified { $0.font = font }
    }

    /// The alignment of text, images and QR codes inside that have not chosen their own.
    public func alignment(_ alignment: ReceiptAlignment) -> ModifiedContent {
        ModifiedContent(nodes: _receiptNodes().nodes, override: StyleOverride(), alignment: alignment)
    }

    private func modified(_ change: (inout StyleOverride) -> Void) -> ModifiedContent {
        var override = StyleOverride()
        change(&override)
        return ModifiedContent(nodes: _receiptNodes().nodes, override: override, alignment: nil)
    }
}
