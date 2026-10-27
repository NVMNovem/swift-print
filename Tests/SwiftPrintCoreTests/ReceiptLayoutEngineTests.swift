//
//  ReceiptLayoutEngineTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import Testing
@testable import SwiftPrintCore

/// Metrics with one dot per cell, so widths read as columns; `€` takes three cells, as it does on a
/// printer that prints it as `EUR`.
private struct ColumnMetrics: TextMetrics {
    let lineWidth: Int
    var maximumMagnification = 8
    var hasSecondaryFont = false

    func cellWidth(of font: PrintFont) -> Int? {
        font == .primary || hasSecondaryFont ? 1 : nil
    }

    func cells(for character: Character) -> Int {
        character == "€" ? 3 : 1
    }
}

@Suite("Receipt layout")
struct ReceiptLayoutEngineTests {
    private func layout(
        _ blocks: [ReceiptBlock],
        columns: Int = 16,
        capabilities: PrintCapabilities = [.underline, .inverted, .images, .qrCodes],
        maximumMagnification: Int = 8
    ) -> LaidOutReceipt {
        ReceiptLayoutEngine(
            metrics: ColumnMetrics(lineWidth: columns, maximumMagnification: maximumMagnification),
            capabilities: capabilities
        )
        .layout(blocks)
    }

    private func text(_ string: String, _ alignment: PrintAlignment = .leading) -> ReceiptBlock {
        .text([StyledRun(string)], alignment: alignment)
    }

    @Test("Text wraps at spaces and drops the spaces at a break")
    func wraps() {
        #expect(layout([text("Friet met mayonaise en stoofvlees")]).plainText == """
        Friet met
        mayonaise en
        stoofvlees
        """)
    }

    @Test("A word longer than the line is broken between characters")
    func longWord() {
        #expect(layout([text("Stoofvleessausvanhethuis")], columns: 10).plainText == "Stoofvlees\nsausvanhet\nhuis")
    }

    @Test("Leading spaces indent the text and each line after a break, but not a wrapped line")
    func indentation() {
        #expect(layout([text("   + Mayonaise\n  + Stoofvlees met saus")], columns: 16).plainText == """
           + Mayonaise
          + Stoofvlees
        met saus
        """)
    }

    @Test("Line breaks in the text start new lines")
    func lineBreaks() {
        #expect(layout([text("a\n\nb")]).plainText == "a\n\nb")
    }

    @Test("Centered and trailing text are padded with plain spaces")
    func alignment() {
        #expect(layout([text("#42", .center), text("18.15", .trailing)], columns: 10).plainText == "   #42\n     18.15")
    }

    @Test("A row keeps its price on the first line and wraps the name under itself")
    func row() {
        let row = ReceiptRow(
            leading: [[StyledRun("2×")], [StyledRun("Bitterballen met mosterd")]],
            trailing: [[StyledRun("€ 6,40")]]
        )
        #expect(layout([.row(row)], columns: 24).plainText == """
        2× Bitterballen € 6,40
           met mosterd
        """)
    }

    @Test("The leading text of a row with only a trailing price is flexible")
    func rowWithoutQuantity() {
        let row = ReceiptRow(leading: [[StyledRun("Totaal")]], trailing: [[StyledRun("€ 12,80")]])
        #expect(layout([.row(row)], columns: 20).plainText == "Totaal     € 12,80")
    }

    @Test("A row whose fixed columns leave no room is wrapped as text and reported")
    func rowOverflow() {
        let row = ReceiptRow(leading: [[StyledRun("aaaaaa")], [StyledRun("b")]], trailing: [[StyledRun("cccccc")]])
        let laidOut = layout([.row(row)], columns: 10)
        #expect(laidOut.degradations == [.rowOverflow])
        #expect(laidOut.plainText == "aaaaaa b\ncccccc")
    }

    @Test("Double width counts twice")
    func doubleWidth() {
        let block = ReceiptBlock.text([StyledRun("#42", style: TextStyle(size: .double))], alignment: .center)
        #expect(layout([block], columns: 10).plainText == "  #42")
    }

    @Test("Width follows the printer's encoding, not the character count")
    func encodedWidth() {
        #expect(layout([text("€€ €€", .trailing)], columns: 16).plainText == "   €€ €€")
    }

    @Test("A style the printer lacks is left off and reported once")
    func missingStyle() {
        let underlined = TextStyle(isUnderlined: true)
        let laidOut = layout(
            [.text([StyledRun("a", style: underlined)], alignment: .leading), .text([StyledRun("b", style: underlined)], alignment: .leading)],
            capabilities: []
        )
        #expect(laidOut.lines == [.text([StyledRun("a")]), .text([StyledRun("b")])])
        #expect(laidOut.degradations == [.styleUnavailable(.underline)])
    }

    @Test("Magnification above the printer's maximum is reduced and reported")
    func magnification() {
        let block = ReceiptBlock.text([StyledRun("A", style: TextStyle(size: TextSize(width: 4, height: 4)))], alignment: .leading)
        let laidOut = layout([block], maximumMagnification: 2)
        #expect(laidOut.lines == [.text([StyledRun("A", style: TextStyle(size: .double))])])
        #expect(laidOut.degradations == [.magnificationReduced(requested: TextSize(width: 4, height: 4), printed: .double)])
    }

    @Test("Images and QR codes are left off, and reported, without the capability")
    func omittedPictures() {
        let image = PrintImage(width: 2, height: 1, pixels: [0, 255])!
        let laidOut = layout([.image(image, alignment: .center), .qrCode(PrintQRCode("x"), alignment: .center)], capabilities: [])
        #expect(laidOut.lines.isEmpty)
        #expect(laidOut.degradations == [.imageOmitted, .qrCodeOmitted])
    }

    @Test("A divider fills the line; spacing adds blank lines")
    func dividerAndSpacing() {
        #expect(layout([.divider("=", style: .plain), .spacing(lines: 2), text("x")], columns: 5).plainText == "=====\n\n\nx")
    }

    @Test("Padding between columns is plain even when the columns are inverted")
    func plainPadding() {
        let inverted = TextStyle(isInverted: true)
        let row = ReceiptRow(leading: [[StyledRun("a", style: inverted)]], trailing: [[StyledRun("b", style: inverted)]])
        #expect(layout([.row(row)], columns: 4).lines == [
            .text([StyledRun("a", style: inverted), StyledRun("  "), StyledRun("b", style: inverted)]),
        ])
    }

    // MARK: - Elements

    private func layout(_ elements: [PrintElement], capabilities: PrintCapabilities = [.qrCodes, .barcodes]) -> LaidOutReceipt {
        ReceiptLayoutEngine(metrics: ColumnMetrics(lineWidth: 16), capabilities: capabilities)
            .layout(elements)
    }

    @Test("A vertical stack is its children with blank lines between those that print")
    func verticalStack() {
        let stack = PrintElement.verticalStack(
            [.text([StyledRun("a")], alignment: .leading), .spacer, .text([StyledRun("b")], alignment: .leading)],
            spacing: .lines(1)
        )
        #expect(layout([stack]).plainText == "a\n\nb")
    }

    @Test("Spacing in a physical unit is rounded up to whole lines")
    func physicalSpacing() {
        // The default line height is 30 dots at 8 dots/mm: 4 mm is 32 dots, so two lines.
        let stack = PrintElement.verticalStack(
            [.text([StyledRun("a")], alignment: .leading), .text([StyledRun("b")], alignment: .leading)],
            spacing: .millimeters(4)
        )
        #expect(layout([stack]).plainText == "a\n\n\nb")
    }

    @Test("A horizontal stack is one row; nested stacks give it their text as columns")
    func horizontalStack() {
        let row = PrintElement.horizontalStack([
            .verticalStack([.text([StyledRun("1×")], alignment: .leading)], spacing: .zero),
            .text([StyledRun("Friet")], alignment: .leading),
            .spacer,
            .text([StyledRun("3,20")], alignment: .leading),
        ], alignment: .leading)
        #expect(layout([row]).plainText == "1× Friet    3,20")
    }

    @Test("Padding is left off a receipt and reported")
    func padding() {
        let laidOut = layout([.padding(PrintInsets(8), .text([StyledRun("a")], alignment: .leading))])
        #expect(laidOut.plainText == "a")
        #expect(laidOut.degradations == [.paddingIgnored])
    }

    @Test("Barcodes print where the printer has them and are left off, reported, where it does not")
    func barcodes() {
        let barcode = PrintElement.barcode(PrintBarcode("1042"), alignment: .center)
        #expect(layout([barcode]).lines == [.barcode(PrintBarcode("1042"), alignment: .center)])
        let omitted = layout([barcode], capabilities: [])
        #expect(omitted.lines.isEmpty)
        #expect(omitted.degradations == [.barcodeOmitted])
    }

}
