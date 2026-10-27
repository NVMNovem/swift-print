//
//  Printer.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A printer: which driver speaks to it, what is done around each receipt and, optionally, how its
/// bytes reach it.
///
/// This is the one API an application prints through. It lays out with the layout the document's
/// format names, renders with the driver and, given a transport, sends; it does not queue, retry or
/// remember. Two calls to one printer at once are the caller's to prevent.
public struct Printer: Sendable {
    /// The protocol the printer speaks.
    public var driver: any PrintDriver
    /// Paper, cut and feed for every receipt.
    public var options: PrintOptions
    /// How bytes reach the printer, or `nil` for a printer that only renders.
    public var transport: (any PrintTransport)?

    public init(
        driver: some PrintDriver,
        options: PrintOptions = PrintOptions(),
        transport: (any PrintTransport)? = nil
    ) {
        self.driver = driver
        self.options = options
        self.transport = transport
    }

    /// What the printer can do with the configured options.
    public var capabilities: PrintCapabilities {
        driver.capabilities(for: options)
    }

    /// The document placed for this printer, by the layout its format names. No I/O.
    ///
    /// Throws ``PrintError/Reason/unsupported(_:)`` when the driver does not print the format, such
    /// as a label on a receipt printer.
    public func layout(_ document: PrintDocument) throws(PrintError) -> LaidOutDocument {
        switch document.format {
        case .receipt:
            let driver = try receiptDriver()
            let metrics = try driver.metrics(for: options)
            return .receipt(ReceiptLayoutEngine(metrics: metrics, capabilities: capabilities).layout(document))
        case .label(let size):
            let driver = try labelDriver()
            let metrics = try driver.labelMetrics(for: options)
            return .label(try LabelLayoutEngine(metrics: metrics, capabilities: capabilities).layout(document.content, size: size))
        }
    }

    /// The bytes this printer would receive. No I/O.
    public func render(_ document: PrintDocument) throws(PrintError) -> RenderedDocument {
        switch try layout(document) {
        case .receipt(let receipt):
            var rendered = try receiptDriver().render(receipt, options: options)
            rendered.degradations = Self.merged(receipt.degradations, rendered.degradations)
            return rendered
        case .label(let label):
            return try labelDriver().render(label, options: options)
        }
    }

    /// The bytes this printer would receive for the content. No I/O.
    public func render(_ content: some PrintContent) throws(PrintError) -> RenderedDocument {
        try render(PrintDocument(content))
    }

    /// Renders a document and sends it over the transport.
    ///
    /// Success means the printer accepted every byte — not that paper came out, unless the outcome's
    /// acknowledgement is ``PrintOutcome/Acknowledgement/completionConfirmed``. On failure,
    /// ``PrintError/delivery`` says whether trying again could print it twice.
    public func print(_ document: PrintDocument) async throws(PrintError) -> PrintOutcome {
        guard let transport else {
            throw PrintError(delivery: .notSent, reason: .unsupported("sending, without a transport"))
        }
        let rendered = try render(document)
        var outcome = try await transport.send(rendered.bytes)
        outcome.degradations = Self.merged(rendered.degradations, outcome.degradations)
        return outcome
    }

    /// Renders and sends the content; see ``print(_:)-(PrintDocument)``.
    public func print(_ content: sending some PrintContent) async throws(PrintError) -> PrintOutcome {
        try await print(PrintDocument(content))
    }

    /// Asks the printer how it is, where the transport and printer can answer.
    public func status() async throws(PrintError) -> PrinterStatus {
        guard let transport else {
            throw PrintError(delivery: .notSent, reason: .unsupported("status, without a transport"))
        }
        return try await transport.status()
    }

    // MARK: - Helpers

    private func receiptDriver() throws(PrintError) -> any ReceiptDriver {
        guard let driver = driver as? any ReceiptDriver else {
            throw PrintError(delivery: .notSent, reason: .unsupported("receipts, with this driver"))
        }
        return driver
    }

    private func labelDriver() throws(PrintError) -> any LabelDriver {
        guard let driver = driver as? any LabelDriver else {
            throw PrintError(delivery: .notSent, reason: .unsupported("labels, with this driver"))
        }
        return driver
    }

    private static func merged(_ first: [PrintDegradation], _ second: [PrintDegradation]) -> [PrintDegradation] {
        var result = first
        for degradation in second where !result.contains(degradation) {
            result.append(degradation)
        }
        return result
    }
}
