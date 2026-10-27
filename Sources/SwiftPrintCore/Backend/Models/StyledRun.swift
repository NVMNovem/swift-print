//
//  StyledRun.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Text in one style.
public struct StyledRun: Sendable, Hashable {
    /// The characters.
    public var text: String
    /// How they are printed.
    public var style: TextStyle

    public init(_ text: String, style: TextStyle = .plain) {
        self.text = text
        self.style = style
    }
}
