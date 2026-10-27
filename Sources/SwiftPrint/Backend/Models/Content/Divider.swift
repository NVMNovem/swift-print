//
//  Divider.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A line across the width: the character repeated on a receipt, a thin rule on a label.
public struct Divider: PrintContent {
    let character: Character

    /// A line of `character`, as many as fit the width.
    public init(_ character: Character = "-") {
        self.character = character
    }

    public var body: Never {
        return fatalError("Divider has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.divider(character)])
    }
}
