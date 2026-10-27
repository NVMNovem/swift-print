//
//  PrinterStatus+ZPL.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

extension PrinterStatus {
    /// The status a ZPL printer reported to `~HS`, for a ``PrintTransport`` that reads it.
    ///
    /// A paused printer is not online; an open head is an open cover. Anything else that stops a
    /// label — a ribbon out in thermal-transfer mode, a full buffer, lost configuration or the head's
    /// temperature — is an error.
    public init(_ status: ZPLHostStatus) {
        self.init(
            isOnline: !status.isPaused,
            isCoverOpen: status.isHeadUp,
            isPaperNearEnd: nil,
            isPaperOut: status.isPaperOut,
            hasError: (status.isThermalTransferMode && status.isRibbonOut)
                || status.isReceiveBufferFull || status.isConfigurationCorrupt
                || status.isUnderTemperature || status.isOverTemperature
        )
    }
}
