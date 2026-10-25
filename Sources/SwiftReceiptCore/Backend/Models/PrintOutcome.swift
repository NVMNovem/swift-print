//
//  PrintOutcome.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A receipt that was handed to the printer completely.
public struct PrintOutcome: Sendable, Hashable {
    /// What the printer said afterwards.
    public enum Acknowledgement: Sendable, Hashable {
        /// Nothing. The bytes were accepted; whether paper came out is not known.
        case none
        /// The printer reported its status after the job.
        case statusReported(ReceiptPrinterStatus)
        /// The printer reported that it finished this job. Only drivers whose protocol genuinely
        /// reports completion answer this.
        case completionConfirmed
    }

    public var bytesSent: Int
    public var acknowledgement: Acknowledgement
    public var degradations: [ReceiptDegradation]
    public var duration: Duration

    public init(
        bytesSent: Int,
        acknowledgement: Acknowledgement = .none,
        degradations: [ReceiptDegradation] = [],
        duration: Duration = .zero
    ) {
        self.bytesSent = bytesSent
        self.acknowledgement = acknowledgement
        self.degradations = degradations
        self.duration = duration
    }
}
