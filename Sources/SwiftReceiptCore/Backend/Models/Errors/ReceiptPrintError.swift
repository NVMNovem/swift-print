//
//  ReceiptPrintError.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Why printing failed, and whether any of the receipt may already be on paper.
///
/// ``delivery`` is the part a caller must act on: only ``Delivery/notSent`` makes trying again
/// safe from printing twice.
public struct ReceiptPrintError: Error, Sendable, Hashable {
    /// How much of the receipt reached the printer.
    public enum Delivery: Sendable, Hashable {
        /// Nothing reached the printer.
        case notSent
        /// Sending had started; `confirmedBytes` were accepted and more may have been. The printer
        /// may have printed part, all or none of the receipt.
        case partiallySent(confirmedBytes: Int)
        /// Everything was accepted, and a step after it failed.
        case sent
    }

    /// The step that failed.
    public enum Phase: Sendable, Hashable {
        /// Opening the connection.
        case connecting
        /// Sending the receipt.
        case writing
        /// Waiting for the printer's status.
        case readingStatus
    }

    /// What went wrong.
    public enum Reason: Sendable, Hashable {
        /// The printer refused the connection.
        case connectionRefused
        /// The connection failed for another reason, described.
        case connectionFailed(String)
        /// A step took longer than its timeout in ``PrintOptions``.
        case timedOut(Phase)
        /// The task was cancelled during a step.
        case cancelled(Phase)
        /// The printer closed the connection during a step.
        case disconnected(Phase)
        /// The printer reported a problem, such as an open cover or no paper.
        case printerReportedProblem(ReceiptPrinterStatus)
        /// The driver or printer cannot do what was asked, such as a paper width or reading status.
        case unsupported(String)
        /// The driver could not turn the receipt into bytes, described.
        case renderingFailed(String)
    }

    /// How much of the receipt reached the printer.
    public let delivery: Delivery
    /// What went wrong.
    public let reason: Reason

    public init(delivery: Delivery, reason: Reason) {
        self.delivery = delivery
        self.reason = reason
    }
}
