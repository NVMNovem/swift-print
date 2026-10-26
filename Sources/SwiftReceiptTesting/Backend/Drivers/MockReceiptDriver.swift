//
//  MockReceiptDriver.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import SwiftReceiptCore

/// A driver for tests: renders plain text, records what it was asked to send, and answers with
/// the responses it was given — so a caller's handling of every outcome can be tested without a
/// printer.
public struct MockReceiptDriver: ReceiptDriver {
    /// What one call to `send` does.
    public enum Response: Sendable, Hashable {
        /// Accepts the receipt and answers with this acknowledgement.
        case success(PrintOutcome.Acknowledgement)
        /// Throws this error.
        case failure(ReceiptPrintError)
    }

    /// Everything sent, and the responses still to give.
    public actor Journal {
        /// Every receipt sent, in order, including those answered with a failure.
        public private(set) var sent: [RenderedReceipt] = []
        private var responses: [Response]

        init(responses: [Response]) {
            self.responses = responses.isEmpty ? [.success(.none)] : responses
        }

        /// Records a receipt and answers with the next response; the last one repeats.
        func send(_ receipt: RenderedReceipt) -> Response {
            sent.append(receipt)
            return responses.count > 1 ? responses.removeFirst() : responses[0]
        }
    }

    /// What the pretend printer can do.
    public let supportedCapabilities: ReceiptCapabilities
    /// Cells per line, one dot each.
    public let columns: Int
    /// The answer to a status request, or `nil` for a printer that cannot report one.
    public let printerStatus: ReceiptPrinterStatus?
    /// Everything sent, shared by every copy of this driver.
    public let journal: Journal

    /// - Parameters:
    ///   - capabilities: What the pretend printer can do.
    ///   - columns: Cells per line, one dot each.
    ///   - responses: Answers to successive sends; the last repeats.
    ///   - status: The answer to a status request, or `nil` for a printer that cannot report one.
    public init(
        capabilities: ReceiptCapabilities = [.underline, .inverted, .images, .qrCodes, .fullCut, .partialCut, .status],
        columns: Int = 48,
        responses: [Response] = [.success(.none)],
        status: ReceiptPrinterStatus? = ReceiptPrinterStatus(isOnline: true)
    ) {
        self.supportedCapabilities = capabilities
        self.columns = columns
        self.printerStatus = status
        self.journal = Journal(responses: responses)
    }

    public func capabilities(for options: PrintOptions) -> ReceiptCapabilities {
        supportedCapabilities
    }

    public func metrics(for options: PrintOptions) throws(ReceiptPrintError) -> any TextMetrics {
        Metrics(lineWidth: columns)
    }

    public func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(ReceiptPrintError) -> RenderedReceipt {
        RenderedReceipt(bytes: Array(receipt.plainText.utf8), degradations: receipt.degradations)
    }

    public func send(
        _ receipt: RenderedReceipt,
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> PrintOutcome {
        switch await journal.send(receipt) {
        case .success(let acknowledgement):
            return PrintOutcome(bytesSent: receipt.bytes.count, acknowledgement: acknowledgement, degradations: receipt.degradations)
        case .failure(let error):
            throw error
        }
    }

    public func status(
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> ReceiptPrinterStatus {
        guard let printerStatus else {
            throw ReceiptPrintError(delivery: .notSent, reason: .unsupported("status, on this mock"))
        }
        return printerStatus
    }

    struct Metrics: TextMetrics {
        let lineWidth: Int
        let maximumMagnification = 8

        func cellWidth(of font: ReceiptFont) -> Int? {
            1
        }

        func cells(for character: Character) -> Int {
            1
        }
    }
}
