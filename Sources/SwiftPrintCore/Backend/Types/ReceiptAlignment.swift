//
//  ReceiptAlignment.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Where a line, an image or a QR code sits across the paper.
public enum ReceiptAlignment: Sendable, Hashable, CaseIterable {
    /// Against the left edge of the paper.
    case leading
    /// In the middle of the paper.
    case center
    /// Against the right edge of the paper.
    case trailing
}
