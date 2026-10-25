//
//  ESCPOSReceiptMapping.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

#if ESCPOS
internal import SwiftESCPOS

extension ReceiptPrintError {
    /// The receipt error for a swift-escpos connection failure, keeping its delivery exactly.
    init(_ error: ESCPOSConnectionError) {
        let delivery: Delivery = switch error.delivery {
        case .notSent: .notSent
        case .partiallySent(let confirmedBytes): .partiallySent(confirmedBytes: confirmedBytes)
        }
        let reason: Reason = switch error.reason {
        case .connectionRefused: .connectionRefused
        case .connectionFailed(let description): .connectionFailed(description)
        case .timedOut(let phase): .timedOut(Phase(phase))
        case .cancelled(let phase): .cancelled(Phase(phase))
        case .disconnected(let phase): .disconnected(Phase(phase))
        case .malformedStatus(let status):
            .connectionFailed("The printer answered a status request with byte \(status.byte).")
        }
        self.init(delivery: delivery, reason: reason)
    }
}

extension ReceiptPrintError.Phase {
    init(_ phase: ESCPOSConnectionError.Phase) {
        switch phase {
        case .connecting: self = .connecting
        case .writing: self = .writing
        case .readingStatus: self = .readingStatus
        }
    }
}

extension ReceiptPrinterStatus {
    init(_ status: ESCPOSPrinterStatus) {
        let errors = [status.hasError, status.hasMechanicalError, status.hasAutocutterError, status.hasUnrecoverableError]
            .compactMap { $0 }
        self.init(
            isOnline: status.isOnline,
            isCoverOpen: status.isCoverOpen,
            isPaperNearEnd: status.isPaperNearEnd,
            isPaperOut: status.isPaperOut == true || status.hasStoppedOnPaperEnd == true
                ? true
                : status.isPaperOut,
            hasError: errors.isEmpty ? nil : errors.contains(true)
        )
    }
}
#endif
