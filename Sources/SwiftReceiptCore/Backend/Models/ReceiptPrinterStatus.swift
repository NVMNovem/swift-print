//
//  ReceiptPrinterStatus.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// What a printer reported about itself. A field is `nil` when nothing covered it.
public struct ReceiptPrinterStatus: Sendable, Hashable {
    /// Whether the printer is accepting jobs.
    public var isOnline: Bool?
    /// Whether the cover is open.
    public var isCoverOpen: Bool?
    /// Whether the roll is nearly finished.
    public var isPaperNearEnd: Bool?
    /// Whether the printer has run out of paper.
    public var isPaperOut: Bool?
    /// Whether the printer reports any error, such as a jammed cutter.
    public var hasError: Bool?

    public init(
        isOnline: Bool? = nil,
        isCoverOpen: Bool? = nil,
        isPaperNearEnd: Bool? = nil,
        isPaperOut: Bool? = nil,
        hasError: Bool? = nil
    ) {
        self.isOnline = isOnline
        self.isCoverOpen = isCoverOpen
        self.isPaperNearEnd = isPaperNearEnd
        self.isPaperOut = isPaperOut
        self.hasError = hasError
    }

    /// `false` when anything known stops a job, `true` when the printer is online and nothing known
    /// stops it, `nil` when there is nothing to go on.
    public var isReady: Bool? {
        if isOnline == false || isCoverOpen == true || isPaperOut == true || hasError == true {
            return false
        }
        return isOnline
    }
}
