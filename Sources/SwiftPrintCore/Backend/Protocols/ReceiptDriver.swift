//
//  ReceiptDriver.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Speaks one printer protocol: measures, renders and sends.
///
/// A driver is a value. It holds no connection and no queue; ``PrintOptions`` and the
/// ``ReceiptConnection`` are handed to it for each call.
public protocol ReceiptDriver: Sendable {
    /// What the printer can do with these options, such as at this paper width.
    func capabilities(for options: PrintOptions) -> ReceiptCapabilities
    /// How wide text prints with these options. Throws when the printer cannot take them, such as a
    /// paper width it lacks.
    func metrics(for options: PrintOptions) throws(ReceiptPrintError) -> any TextMetrics
    /// The bytes for a laid-out receipt, with anything printed differently. No I/O.
    func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(ReceiptPrintError) -> RenderedReceipt
    /// Sends rendered bytes to the printer.
    ///
    /// A thrown error's ``ReceiptPrintError/delivery`` must say exactly how much reached the
    /// printer, so a caller knows whether trying again could print twice.
    func send(
        _ receipt: RenderedReceipt,
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> PrintOutcome
    /// Asks the printer for its status, or throws ``ReceiptPrintError/Reason/unsupported(_:)`` when
    /// the driver or printer cannot answer.
    func status(
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> ReceiptPrinterStatus
}
