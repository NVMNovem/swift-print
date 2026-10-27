//
//  PrintContent+Modifiers.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

extension PrintContent {
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
    public func size(_ size: TextSize) -> ModifiedContent {
        modified { $0.size = size }
    }

    /// The printer font of all text inside that has not chosen its own.
    public func font(_ font: PrintFont) -> ModifiedContent {
        modified { $0.font = font }
    }

    /// The alignment of text, images and codes inside that have not chosen their own.
    public func alignment(_ alignment: PrintAlignment) -> ModifiedContent {
        ModifiedContent(nodes: _printNodes().nodes, override: StyleOverride(), alignment: alignment)
    }

    /// The same space on every side. Labels only: a receipt is placed at the paper's width and
    /// leaves padding off, reporting ``PrintDegradation/paddingIgnored``.
    public func padding(_ length: PrintLength) -> ModifiedContent {
        padding(PrintInsets(length))
    }

    /// Space on each side; see ``padding(_:)-(PrintLength)``.
    public func padding(
        top: PrintLength = .zero,
        leading: PrintLength = .zero,
        bottom: PrintLength = .zero,
        trailing: PrintLength = .zero
    ) -> ModifiedContent {
        padding(PrintInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
    }

    /// Space on each side; see ``padding(_:)-(PrintLength)``.
    public func padding(_ insets: PrintInsets) -> ModifiedContent {
        ModifiedContent(node: .padding(insets, _printNodes().nodes))
    }

    private func modified(_ change: (inout StyleOverride) -> Void) -> ModifiedContent {
        var override = StyleOverride()
        change(&override)
        return ModifiedContent(nodes: _printNodes().nodes, override: override, alignment: nil)
    }
}
