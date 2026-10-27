//
//  PrintAlignment.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Where a line, a picture or a code sits across the space it has: the paper on a receipt, its
/// stack on a label.
public enum PrintAlignment: Sendable, Hashable, CaseIterable {
    /// Against the left edge.
    case leading
    /// In the middle.
    case center
    /// Against the right edge.
    case trailing
}
