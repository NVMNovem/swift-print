//
//  StyledRun.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Text in one style.
public struct StyledRun: Sendable, Hashable {
    public var text: String
    public var style: TextStyle

    public init(_ text: String, style: TextStyle = .plain) {
        self.text = text
        self.style = style
    }
}
