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
    public enum Delivery: Sendable, Hashable {
        /// Nothing reached the printer.
        case notSent
        /// Sending had started; `confirmedBytes` were accepted and more may have been. The printer
        /// may have printed part, all or none of the receipt.
        case partiallySent(confirmedBytes: Int)
        /// Everything was accepted, and a step after it failed.
        case sent
    }

    public enum Phase: Sendable, Hashable {
        case connecting
        case writing
        case readingStatus
    }

    public enum Reason: Sendable, Hashable {
        case connectionRefused
        case connectionFailed(String)
        case timedOut(Phase)
        case cancelled(Phase)
        case disconnected(Phase)
        case printerReportedProblem(ReceiptPrinterStatus)
        /// The driver or printer cannot do what was asked, such as a paper width or reading status.
        case unsupported(String)
        case renderingFailed(String)
    }

    public let delivery: Delivery
    public let reason: Reason

    public init(delivery: Delivery, reason: Reason) {
        self.delivery = delivery
        self.reason = reason
    }
}
