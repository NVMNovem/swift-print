//
//  ReceiptLayoutTests.swift
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

    func cellWidth(of font: ReceiptFont) -> Int? {
        font == .primary || hasSecondaryFont ? 1 : nil
    }

    func cells(for character: Character) -> Int {
        character == "€" ? 3 : 1
    }
}

@Suite("Layout")
struct ReceiptLayoutTests {
    private func layout(
        _ blocks: [ReceiptBlock],
        columns: Int = 16,
        capabilities: ReceiptCapabilities = [.underline, .inverted, .images, .qrCodes],
        maximumMagnification: Int = 8
    ) -> LaidOutReceipt {
        ReceiptLayout(
            metrics: ColumnMetrics(lineWidth: columns, maximumMagnification: maximumMagnification),
            capabilities: capabilities
        )
        .layout(ReceiptDocument(blocks: blocks))
    }

    private func text(_ string: String, _ alignment: ReceiptAlignment = .leading) -> ReceiptBlock {
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
        let block = ReceiptBlock.text([StyledRun("A", style: TextStyle(size: ReceiptTextSize(width: 4, height: 4)))], alignment: .leading)
        let laidOut = layout([block], maximumMagnification: 2)
        #expect(laidOut.lines == [.text([StyledRun("A", style: TextStyle(size: .double))])])
        #expect(laidOut.degradations == [.magnificationReduced(requested: ReceiptTextSize(width: 4, height: 4), printed: .double)])
    }

    @Test("Images and QR codes are left off, and reported, without the capability")
    func omittedPictures() {
        let image = ReceiptImage(width: 2, height: 1, pixels: [0, 255])!
        let laidOut = layout([.image(image, alignment: .center), .qrCode(ReceiptQRCode("x"), alignment: .center)], capabilities: [])
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
}
