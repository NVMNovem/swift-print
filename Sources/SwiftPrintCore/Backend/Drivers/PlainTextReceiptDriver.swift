//
//  PlainTextReceiptDriver.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Renders a receipt as plain UTF-8 text: one character per cell, styles ignored, pictures and
/// codes as placeholders. For previews, logs and tests.
public struct PlainTextReceiptDriver: ReceiptDriver {
    public init() {}

    public func capabilities(for options: PrintOptions) -> PrintCapabilities {
        [.underline, .inverted, .images, .qrCodes, .barcodes, .fullCut, .partialCut]
    }

    public func metrics(for options: PrintOptions) throws(PrintError) -> any TextMetrics {
        Metrics(lineWidth: options.receipt.paperWidth == .millimeters58 ? 32 : 48)
    }

    public func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(PrintError) -> RenderedDocument {
        RenderedDocument(bytes: Array((receipt.plainText + "\n").utf8), degradations: receipt.degradations)
    }

    struct Metrics: TextMetrics {
        let lineWidth: Int
        let maximumMagnification = 8

        func cellWidth(of font: PrintFont) -> Int? {
            font == .primary ? 1 : nil
        }

        func cells(for character: Character) -> Int {
            1
        }
    }
}
