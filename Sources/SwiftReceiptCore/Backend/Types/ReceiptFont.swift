//
//  ReceiptFont.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// The printer's own fonts: its standard one and, where it has one, a condensed one.
public enum ReceiptFont: Sendable, Hashable, CaseIterable {
    case primary
    case secondary
}
