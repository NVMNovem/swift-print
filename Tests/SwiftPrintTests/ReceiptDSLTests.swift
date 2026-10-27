//
//  ReceiptDSLTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import Testing
@testable import SwiftPrint

private struct Line: Sendable {
    let quantity: Int
    let name: String
    let price: String
}

private struct TicketReceipt: ReceiptContent {
    let lines: [Line]
    let note: String?

    var body: some ReceiptContent {
        VStack(spacing: 1) {
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

@Suite("Receipt DSL")
struct ReceiptDSLTests {
    @Test("A declared receipt lowers to the blocks it describes")
    func lowering() {
        let document = ReceiptDocument(TicketReceipt(
            lines: [Line(quantity: 2, name: "Friet", price: "€ 6,40")],
            note: "Zonder zout"
        ))
        let title = TextStyle(isBold: true, size: .double)
        #expect(document.blocks == [
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
        let document = ReceiptDocument(TicketReceipt(lines: [], note: nil))
        #expect(document.blocks.count == 3)
    }

    @Test("An inner modifier wins over an outer one")
    func modifierPrecedence() {
        let document = ReceiptDocument(VStack {
            Text("a")
            Text("b").bold(false)
        }.bold())
        #expect(document.blocks == [
            .text([StyledRun("a", style: TextStyle(isBold: true))], alignment: .leading),
            .text([StyledRun("b")], alignment: .leading),
        ])
    }

    @Test("Joined texts keep their own styles on one line")
    func concatenation() {
        let document = ReceiptDocument(Text("Totaal").bold() + Text(" incl. btw"))
        #expect(document.blocks == [
            .text([StyledRun("Totaal", style: TextStyle(isBold: true)), StyledRun(" incl. btw")], alignment: .leading),
        ])
    }

    @Test("Alignment set on a container reaches its text, images and QR codes")
    func containerAlignment() {
        let document = ReceiptDocument(VStack {
            "Bedankt"
            QRCode("https://frietheus.ordessa.app/o/abc")
        }.alignment(.center))
        #expect(document.blocks == [
            .text([StyledRun("Bedankt")], alignment: .center),
            .qrCode(ReceiptQRCode("https://frietheus.ordessa.app/o/abc"), alignment: .center),
        ])
    }

    @Test("Anything but text in a row is placed after it")
    func rowExtras() {
        let document = ReceiptDocument(HStack {
            Text("a")
            Divider()
            Spacer()
            Text("b")
        })
        #expect(document.blocks == [
            .row(ReceiptRow(leading: [[StyledRun("a")]], trailing: [[StyledRun("b")]])),
            .divider("-", style: .plain),
        ])
    }
}
