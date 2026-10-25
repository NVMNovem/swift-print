//
//  ReceiptConnection.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Where a printer is reached. A driver decides how to talk over it.
public enum ReceiptConnection: Sendable, Hashable {
    /// A network printer, normally on raw port 9100.
    case tcp(host: String, port: Int = 9100)
}
