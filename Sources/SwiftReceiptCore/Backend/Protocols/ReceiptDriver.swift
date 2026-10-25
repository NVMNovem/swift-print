//
//  ReceiptDriver.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Speaks one printer protocol: measures, renders and sends.
///
/// A driver is a value. It holds no connection and no queue; ``PrintOptions`` and the
/// ``ReceiptConnection`` are handed to it for each call.
public protocol ReceiptDriver: Sendable {
    func capabilities(for options: PrintOptions) -> ReceiptCapabilities
    func metrics(for options: PrintOptions) throws(ReceiptPrintError) -> any TextMetrics
    func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(ReceiptPrintError) -> RenderedReceipt
    func send(
        _ receipt: RenderedReceipt,
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> PrintOutcome
    func status(
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> ReceiptPrinterStatus
}
