//
//  PlainTextReceiptDriver.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Renders a receipt as plain UTF-8 text: one character per cell, styles ignored, images and QR
/// codes as placeholders. For previews, logs and tests; it cannot send.
public struct PlainTextReceiptDriver: ReceiptDriver {
    public init() {}

    public func capabilities(for options: PrintOptions) -> ReceiptCapabilities {
        [.underline, .inverted, .images, .qrCodes, .fullCut, .partialCut]
    }

    public func metrics(for options: PrintOptions) throws(ReceiptPrintError) -> any TextMetrics {
        Metrics(lineWidth: options.paperWidth == .millimeters58 ? 32 : 48)
    }

    public func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(ReceiptPrintError) -> RenderedReceipt {
        RenderedReceipt(bytes: Array((receipt.plainText + "\n").utf8), degradations: receipt.degradations)
    }

    public func send(
        _ receipt: RenderedReceipt,
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> PrintOutcome {
        throw ReceiptPrintError(delivery: .notSent, reason: .unsupported("sending, with the plain-text driver"))
    }

    public func status(
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> ReceiptPrinterStatus {
        throw ReceiptPrintError(delivery: .notSent, reason: .unsupported("status, with the plain-text driver"))
    }

    struct Metrics: TextMetrics {
        let lineWidth: Int
        let maximumMagnification = 8

        func cellWidth(of font: ReceiptFont) -> Int? {
            font == .primary ? 1 : nil
        }

        func cells(for character: Character) -> Int {
            1
        }
    }
}
