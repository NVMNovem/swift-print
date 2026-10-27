//
//  PrinterStatus+ESCPOS.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

extension PrinterStatus {
    /// The status an ESC/POS printer reported, for a ``PrintTransport`` that reads it.
    public init(_ status: ESCPOSPrinterStatus) {
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
