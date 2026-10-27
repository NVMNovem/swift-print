//
//  ReceiptDSLTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import Testing
@testable import SwiftPrint
@testable import SwiftPrintCore

private struct Line: Sendable {
    let quantity: Int
    let name: String
    let price: String
}

private struct TicketReceipt: PrintContent {
    let lines: [Line]
    let note: String?

    var body: some PrintContent {
        VStack(spacing: .lines(1)) {
            Text("FrietHeus").bold().size(.double).alignment(.center)
            Divider()
            ForEach(lines) { line in
                HStack {
                    Text("\(line.quantity)×")
                    Text(line.name)
                    Spacer()
                    Text(line.price)
                }
            }
            if let note {
                Text(note)
            }
        }
    }
}

/// One dot per cell, so widths read as columns.
private struct ColumnMetrics: TextMetrics {
    let lineWidth: Int
    let maximumMagnification = 8

    func cellWidth(of font: PrintFont) -> Int? { 1 }
    func cells(for character: Character) -> Int { 1 }
}

@Suite("Receipt DSL")
struct ReceiptDSLTests {
    private func blocks(_ document: ResolvedDocument) -> [ReceiptBlock] {
        ReceiptLayoutEngine(metrics: ColumnMetrics(lineWidth: 32), capabilities: []).blocks(document.content).blocks
    }

    @Test("A declared receipt lowers to the blocks it describes")
    func lowering() {
        let document = ResolvedDocument(ReceiptLayout {
            TicketReceipt(lines: [Line(quantity: 2, name: "Friet", price: "€ 6,40")], note: "Zonder zout")
        })
        let title = TextStyle(isBold: true, size: .double)
        #expect(document.format == .receipt)
        #expect(blocks(document) == [
            .text([StyledRun("FrietHeus", style: title)], alignment: .center),
            .spacing(lines: 1),
            .divider("-", style: .plain),
            .spacing(lines: 1),
            .row(ReceiptRow(leading: [[StyledRun("2×")], [StyledRun("Friet")]], trailing: [[StyledRun("€ 6,40")]])),
            .spacing(lines: 1),
            .text([StyledRun("Zonder zout")], alignment: .leading),
        ])
    }

    @Test("A false condition contributes nothing, not even spacing")
    func condition() {
        let document = ResolvedDocument(ReceiptLayout { TicketReceipt(lines: [], note: nil) })
        #expect(blocks(document).count == 3)
    }

    @Test("An inner modifier wins over an outer one")
    func modifierPrecedence() {
        let document = ResolvedDocument(ReceiptLayout { VStack {
            Text("a")
            Text("b").bold(false)
        }.bold() })
        #expect(document.content == [
            .verticalStack([
                .text([StyledRun("a", style: TextStyle(isBold: true))], alignment: .leading),
                .text([StyledRun("b")], alignment: .leading),
            ], spacing: .zero),
        ])
    }

    @Test("Joined texts keep their own styles on one line")
    func concatenation() {
        let document = ResolvedDocument(ReceiptLayout { Text("Totaal").bold() + Text(" incl. btw") })
        #expect(document.content == [
            .text([StyledRun("Totaal", style: TextStyle(isBold: true)), StyledRun(" incl. btw")], alignment: .leading),
        ])
    }

    @Test("Alignment set on a container reaches its text, pictures and codes")
    func containerAlignment() {
        let document = ResolvedDocument(ReceiptLayout { VStack {
            "Bedankt"
            QRCode("https://frietheus.ordessa.app/o/abc")
            Barcode("1042")
        }.alignment(.center) })
        #expect(document.content == [
            .verticalStack([
                .text([StyledRun("Bedankt")], alignment: .center),
                .qrCode(PrintQRCode("https://frietheus.ordessa.app/o/abc"), alignment: .center),
                .barcode(PrintBarcode("1042"), alignment: .center),
            ], spacing: .zero),
        ])
    }

    @Test("A stack's alignment is the same as the alignment modifier")
    func stackAlignment() {
        let stacked = ResolvedDocument(ReceiptLayout { VStack(alignment: .trailing) { Text("a") } })
        let modified = ResolvedDocument(ReceiptLayout { VStack { Text("a") }.alignment(.trailing) })
        #expect(stacked == modified)
    }

    @Test("A modifier on several pieces keeps them together as one piece of a stack")
    func groupedModifier() {
        let document = ResolvedDocument(ReceiptLayout { VStack(spacing: .lines(1)) {
            Group {
                Text("a")
                Text("b")
            }.bold()
            Text("c")
        } })
        let bold = TextStyle(isBold: true)
        #expect(blocks(document) == [
            .text([StyledRun("a", style: bold)], alignment: .leading),
            .text([StyledRun("b", style: bold)], alignment: .leading),
            .spacing(lines: 1),
            .text([StyledRun("c")], alignment: .leading),
        ])
    }

    @Test("Anything but text in a row is placed after it")
    func rowExtras() {
        let document = ResolvedDocument(ReceiptLayout { HStack {
            Text("a")
            Divider()
            Spacer()
            Text("b")
        } })
        #expect(blocks(document) == [
            .row(ReceiptRow(leading: [[StyledRun("a")]], trailing: [[StyledRun("b")]])),
            .divider("-", style: .plain),
        ])
    }

    @Test("A document resolves through its root layout")
    func document() {
        struct Receipt: PrintDocument {
            var body: some PrintLayout {
                ReceiptLayout { Text("a") }
            }
        }
        #expect(ResolvedDocument(Receipt()) == ResolvedDocument(format: .receipt, content: [.text([StyledRun("a")], alignment: .leading)]))
        #expect(ResolvedDocument(Receipt()) == ResolvedDocument(ReceiptLayout { Text("a") }))
    }
}
