//
//  ReceiptCut.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How the paper is cut after a receipt.
public enum ReceiptCut: Sendable, Hashable, CaseIterable {
    /// Cuts the paper through.
    case full
    /// Leaves the ticket hanging by one point until it is torn off.
    case partial
}
