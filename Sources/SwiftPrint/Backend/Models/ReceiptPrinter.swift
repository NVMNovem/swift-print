//
//  ReceiptPrinter.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A printer: where it is, which driver speaks to it, and what is done around each receipt.
///
/// This is the one API an application prints through. It lays out, renders and sends; it does not
/// queue, retry or remember. Each call opens its own connection, and two calls to one printer at
/// once are the caller's to prevent.
public struct ReceiptPrinter: Sendable {
    /// A name for this printer, chosen by the application.
    public var id: String
    /// Where the printer is reached.
    public var connection: ReceiptConnection
    /// The protocol the printer speaks.
    public var driver: any ReceiptDriver
    /// Paper, cut, feed and timeouts for every receipt.
    public var options: PrintOptions

    public init(
        id: String = "printer",
        connection: ReceiptConnection,
        driver: some ReceiptDriver,
        options: PrintOptions = PrintOptions()
    ) {
        self.id = id
        self.connection = connection
        self.driver = driver
        self.options = options
    }

    /// What the printer can do at the configured paper width.
    public var capabilities: ReceiptCapabilities {
        driver.capabilities(for: options)
    }

    /// The document placed on this printer's paper. No I/O.
    public func layout(_ document: ReceiptDocument) throws(ReceiptPrintError) -> LaidOutReceipt {
        let metrics = try driver.metrics(for: options)
        return ReceiptLayout(metrics: metrics, capabilities: capabilities).layout(document)
    }

    /// The bytes this printer would receive. No I/O.
    public func render(_ document: ReceiptDocument) throws(ReceiptPrintError) -> RenderedReceipt {
        let laidOut = try layout(document)
        var rendered = try driver.render(laidOut, options: options)
        rendered.degradations = Self.merged(laidOut.degradations, rendered.degradations)
        return rendered
    }

    /// The bytes this printer would receive for the content. No I/O.
    public func render(_ content: some ReceiptContent) throws(ReceiptPrintError) -> RenderedReceipt {
        try render(ReceiptDocument(content))
    }

    /// Renders and sends a receipt.
    ///
    /// Success means the printer accepted every byte — not that paper came out, unless the outcome's
    /// acknowledgement is ``PrintOutcome/Acknowledgement/completionConfirmed``. On failure,
    /// ``ReceiptPrintError/delivery`` says whether trying again could print it twice.
    public func print(_ document: ReceiptDocument) async throws(ReceiptPrintError) -> PrintOutcome {
        let rendered = try render(document)
        var outcome = try await driver.send(rendered, over: connection, options: options)
        outcome.degradations = Self.merged(rendered.degradations, outcome.degradations)
        return outcome
    }

    /// Renders and sends the content; see ``print(_:)-(ReceiptDocument)``.
    public func print(_ content: sending some ReceiptContent) async throws(ReceiptPrintError) -> PrintOutcome {
        try await print(ReceiptDocument(content))
    }

    /// Asks the printer how it is, where the driver and printer can answer.
    public func status() async throws(ReceiptPrintError) -> ReceiptPrinterStatus {
        try await driver.status(over: connection, options: options)
    }

    private static func merged(_ first: [ReceiptDegradation], _ second: [ReceiptDegradation]) -> [ReceiptDegradation] {
        var result = first
        for degradation in second where !result.contains(degradation) {
            result.append(degradation)
        }
        return result
    }
}
