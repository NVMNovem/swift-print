//
//  MockDriver.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import SwiftPrintCore

/// A driver for tests that prints receipts and labels as plain text, one dot per cell, so a
/// caller's layout and handling of degradations can be tested without a printer.
public struct MockDriver: ReceiptDriver, LabelDriver {
    /// What the pretend printer can do.
    public let supportedCapabilities: PrintCapabilities
    /// Cells per receipt line, one dot each.
    public let columns: Int
    /// Label dots per millimetre.
    public let dotsPerMillimeter: Double
    /// The height of a line of label text, in dots; every character is half as wide.
    public let textHeight: Int

    /// - Parameters:
    ///   - capabilities: What the pretend printer can do.
    ///   - columns: Cells per receipt line, one dot each.
    ///   - dotsPerMillimeter: Label dots per millimetre.
    ///   - textHeight: The height of a line of label text, in dots.
    public init(
        capabilities: PrintCapabilities = [.underline, .inverted, .images, .qrCodes, .barcodes, .fullCut, .partialCut, .status],
        columns: Int = 48,
        dotsPerMillimeter: Double = 8,
        textHeight: Int = 20
    ) {
        self.supportedCapabilities = capabilities
        self.columns = columns
        self.dotsPerMillimeter = dotsPerMillimeter
        self.textHeight = textHeight
    }

    public func capabilities(for options: PrintOptions) -> PrintCapabilities {
        supportedCapabilities
    }

    public func metrics(for options: PrintOptions) throws(PrintError) -> any TextMetrics {
        ReceiptMetrics(lineWidth: columns)
    }

    public func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(PrintError) -> RenderedDocument {
        RenderedDocument(bytes: Array(receipt.plainText.utf8), degradations: receipt.degradations)
    }

    public func labelMetrics(for options: PrintOptions) throws(PrintError) -> any LabelMetrics {
        LabelTextMetrics(dotsPerMillimeter: dotsPerMillimeter, textHeight: textHeight)
    }

    public func render(_ label: LaidOutLabel, options: PrintOptions) throws(PrintError) -> RenderedDocument {
        RenderedDocument(bytes: Array(label.plainText.utf8))
    }

    struct ReceiptMetrics: TextMetrics {
        let lineWidth: Int
        let maximumMagnification = 8

        func cellWidth(of font: PrintFont) -> Int? {
            1
        }

        func cells(for character: Character) -> Int {
            1
        }
    }

    struct LabelTextMetrics: SwiftPrintCore.LabelMetrics {
        let dotsPerMillimeter: Double
        let textHeight: Int
        let maximumWidth = 32000
        let maximumHeight = 32000
        let maximumMagnification = 8

        func lineHeight(of font: PrintFont) -> Int? {
            font == .primary ? textHeight : nil
        }

        func width(of character: Character, font: PrintFont) -> Int {
            max(1, textHeight / 2)
        }
    }
}
