//
//  ReceiptPaperWidth.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// The width of the paper roll in the printer.
public enum ReceiptPaperWidth: Int, Sendable, Hashable, CaseIterable {
    /// 58 mm paper.
    case millimeters58 = 58
    /// 80 mm paper.
    case millimeters80 = 80
}
