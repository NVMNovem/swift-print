//
//  PrintError.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Why printing failed, and whether any of the document may already be on paper.
///
/// ``delivery`` is the part a caller must act on: only ``Delivery/notSent`` makes trying again
/// safe from printing twice. Layout and rendering never send, so their errors are always
/// ``Delivery/notSent``; a ``PrintTransport`` says exactly how far it got.
public struct PrintError: Error, Sendable, Hashable {
    /// How much of the document reached the printer.
    public enum Delivery: Sendable, Hashable {
        /// Nothing reached the printer.
        case notSent
        /// Sending had started; `confirmedBytes` were accepted and more may have been. The printer
        /// may have printed part, all or none of the document.
        case partiallySent(confirmedBytes: Int)
        /// Everything was accepted, and a step after it failed.
        case sent
    }

    /// The step that failed.
    public enum Phase: Sendable, Hashable {
        /// Opening the connection.
        case connecting
        /// Sending the document.
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
        /// A step took longer than the transport allows.
        case timedOut(Phase)
        /// The task was cancelled during a step.
        case cancelled(Phase)
        /// The printer closed the connection during a step.
        case disconnected(Phase)
        /// The printer reported a problem, such as an open cover or no paper.
        case printerReportedProblem(PrinterStatus)
        /// The printer's driver does not print this layout, such as a label on a receipt printer.
        case layoutUnsupported(PrintLayoutKind)
        /// The printer has no printable width for the paper width in ``ReceiptOptions``.
        case paperWidthUnsupported(ReceiptPaperWidth)
        /// A label's declared dimension is not a size: zero, negative or not a finite number.
        case invalidDimension(PrintDimension, PrintLength)
        /// A label's dimension, in dots, is more than the printer prints.
        case exceedsPrinter(PrintDimension, dots: Int, maximum: Int)
        /// A label's dimension, in dots, is more than the media configured in ``LabelOptions``.
        case exceedsMedia(PrintDimension, dots: Int, media: Int)
        /// The content does not fit the space it was given within the document, described.
        case contentOverflow(String)
        /// The driver or printer cannot do what was asked, such as a QR code on a label printer
        /// without them, or reading status.
        case unsupported(String)
        /// The driver could not turn the document into bytes, described.
        case renderingFailed(String)
    }

    /// How much of the document reached the printer.
    public let delivery: Delivery
    /// What went wrong.
    public let reason: Reason

    public init(delivery: Delivery, reason: Reason) {
        self.delivery = delivery
        self.reason = reason
    }
}

extension PrintError: CustomStringConvertible {
    public var description: String {
        let sent = switch delivery {
        case .notSent: "Nothing was sent"
        case .partiallySent(let confirmedBytes): "\(confirmedBytes) bytes may have been printed"
        case .sent: "Everything was sent"
        }
        return "\(reason). \(sent)."
    }
}

extension PrintError.Reason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connectionRefused: "The printer refused the connection"
        case .connectionFailed(let description): "The connection failed: \(description)"
        case .timedOut(let phase): "Timed out while \(phase)"
        case .cancelled(let phase): "Cancelled while \(phase)"
        case .disconnected(let phase): "The printer disconnected while \(phase)"
        case .printerReportedProblem(let status): "The printer reported a problem: \(status)"
        case .layoutUnsupported(let kind):
            "The printer's driver does not print \(kind == .receipt ? "a ReceiptLayout" : "a LabelLayout")"
        case .paperWidthUnsupported(let width):
            "The printer has no printable width for \(width.rawValue) mm paper, set in PrintOptions.receipt"
        case .invalidDimension(let dimension, let length):
            "The label's \(dimension) of \(length) is not a size"
        case .exceedsPrinter(let dimension, let dots, let maximum):
            "The label's \(dimension) is \(dots) dots; the printer prints at most \(maximum)"
        case .exceedsMedia(let dimension, let dots, let media):
            "The label's \(dimension) is \(dots) dots; the media set in PrintOptions.label is \(media)"
        case .contentOverflow(let description): "The content does not fit: \(description)"
        case .unsupported(let description): "Not supported: \(description)"
        case .renderingFailed(let description): "Rendering failed: \(description)"
        }
    }
}

extension PrintError.Phase: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connecting: "connecting"
        case .writing: "writing"
        case .readingStatus: "reading status"
        }
    }
}
