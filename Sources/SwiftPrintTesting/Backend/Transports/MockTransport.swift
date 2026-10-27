//
//  MockTransport.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

import SwiftPrintCore

/// A transport for tests: records what it was asked to send and answers with the responses it was
/// given — so a caller's handling of every outcome can be tested without a printer.
public struct MockTransport: PrintTransport {
    /// What one call to `send` does.
    public enum Response: Sendable, Hashable {
        /// Accepts the bytes and answers with this acknowledgement.
        case success(PrintOutcome.Acknowledgement)
        /// Throws this error.
        case failure(PrintError)
    }

    /// Everything sent, and the responses still to give.
    public actor Journal {
        /// The bytes of every send, in order, including those answered with a failure.
        public private(set) var sent: [[UInt8]] = []
        private var responses: [Response]

        init(responses: [Response]) {
            self.responses = responses.isEmpty ? [.success(.none)] : responses
        }

        /// Records a send and answers with the next response; the last one repeats.
        func send(_ bytes: [UInt8]) -> Response {
            sent.append(bytes)
            return responses.count > 1 ? responses.removeFirst() : responses[0]
        }
    }

    /// The answer to a status request, or `nil` for a printer that cannot report one.
    public let printerStatus: PrinterStatus?
    /// Everything sent, shared by every copy of this transport.
    public let journal: Journal

    /// - Parameters:
    ///   - responses: Answers to successive sends; the last repeats.
    ///   - status: The answer to a status request, or `nil` for a printer that cannot report one.
    public init(
        responses: [Response] = [.success(.none)],
        status: PrinterStatus? = PrinterStatus(isOnline: true)
    ) {
        self.printerStatus = status
        self.journal = Journal(responses: responses)
    }

    public func send(_ bytes: [UInt8]) async throws(PrintError) -> PrintOutcome {
        switch await journal.send(bytes) {
        case .success(let acknowledgement):
            return PrintOutcome(bytesSent: bytes.count, acknowledgement: acknowledgement)
        case .failure(let error):
            throw error
        }
    }

    public func status() async throws(PrintError) -> PrinterStatus {
        guard let printerStatus else {
            throw PrintError(delivery: .notSent, reason: .unsupported("status, on this mock"))
        }
        return printerStatus
    }
}
