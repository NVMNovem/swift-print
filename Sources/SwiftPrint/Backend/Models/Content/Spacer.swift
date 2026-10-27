//
//  Spacer.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Flexible space.
///
/// In an ``HStack``, the point where leading pieces end and trailing ones begin. In a ``VStack`` on
/// a label, the height the stack has left, shared with any other spacers. Elsewhere, nothing.
public struct Spacer: PrintContent {
    /// Flexible space.
    public init() {}

    public var body: Never {
        return fatalError("Spacer has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.spacer])
    }
}
