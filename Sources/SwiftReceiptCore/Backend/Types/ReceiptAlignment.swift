//
//  ReceiptAlignment.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Where a line, an image or a QR code sits across the paper.
public enum ReceiptAlignment: Sendable, Hashable, CaseIterable {
    case leading
    case center
    case trailing
}
