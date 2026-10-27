//
//  PrinterTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import Testing
import SwiftPrint
import SwiftPrintTesting

@Suite("Printer")
struct PrinterTests {
    private let receipt = VStack {
        Text("#42").size(.double).alignment(.center)
        HStack { Text("Friet"); Spacer(); Text("€ 3,20") }
    }

    @Test("Printing renders, sends over the transport and reports the outcome")
    func prints() async throws {
        let transport = MockTransport()
        let printer = Printer(driver: MockDriver(columns: 16), transport: transport)

        let outcome = try await printer.print(PrintDocument(receipt))

        let sent = await transport.journal.sent
        #expect(sent.count == 1)
        #expect(String(decoding: sent[0], as: UTF8.self) == "     #42\nFriet     € 3,20")
        #expect(outcome.bytesSent == sent[0].count)
        #expect(outcome.acknowledgement == .none)
    }

    @Test("A failure keeps its delivery, so the caller can tell a retry is unsafe")
    func failureKeepsDelivery() async {
        let failure = PrintError(delivery: .partiallySent(confirmedBytes: 12), reason: .disconnected(.writing))
        let printer = Printer(driver: MockDriver(), transport: MockTransport(responses: [.failure(failure)]))
        await #expect(throws: failure) {
            try await printer.print(PrintDocument(receipt))
        }
    }

    @Test("Responses are given in order and the last one repeats")
    func responseOrder() async throws {
        let refused = PrintError(delivery: .notSent, reason: .connectionRefused)
        let transport = MockTransport(responses: [.failure(refused), .success(.completionConfirmed)])
        let printer = Printer(driver: MockDriver(), transport: transport)

        await #expect(throws: refused) { try await printer.print(PrintDocument(receipt)) }
        #expect(try await printer.print(PrintDocument(receipt)).acknowledgement == .completionConfirmed)
        #expect(try await printer.print(PrintDocument(receipt)).acknowledgement == .completionConfirmed)
    }

    @Test("Degradations from layout reach the outcome")
    func degradations() async throws {
        let printer = Printer(driver: MockDriver(capabilities: []), transport: MockTransport())
        let outcome = try await printer.print(PrintDocument(QRCode("x")))
        #expect(outcome.degradations == [.qrCodeOmitted])
    }

    @Test("Without a transport a printer renders, and refuses to send or read status")
    func withoutTransport() async throws {
        let printer = Printer(driver: PlainTextReceiptDriver(), options: PrintOptions(paperWidth: .millimeters58))
        let rendered = try printer.render(receipt)
        #expect(String(decoding: rendered.bytes, as: UTF8.self).hasPrefix("             #42\n"))
        await #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("sending, without a transport"))) {
            try await printer.print(PrintDocument(receipt))
        }
        await #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("status, without a transport"))) {
            try await printer.status()
        }
    }

    @Test("Status comes from the transport")
    func status() async throws {
        let printer = Printer(driver: MockDriver(), transport: MockTransport(status: PrinterStatus(isOnline: true, isPaperOut: true)))
        #expect(try await printer.status().isReady == false)
    }

    @Test("A label is laid out and rendered by a label driver")
    func label() throws {
        let printer = Printer(driver: MockDriver(textHeight: 20))
        let rendered = try printer.render(LabelLayout(width: .millimeters(20), height: .millimeters(10)) {
            Text("1042")
        })
        #expect(String(decoding: rendered.bytes, as: UTF8.self) == "0,0 160×20 text leading \"1042\"")
    }

    @Test("A format the driver does not print is refused before anything is rendered")
    func unsupportedFormat() {
        let receiptPrinter = Printer(driver: PlainTextReceiptDriver())
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("labels, with this driver"))) {
            try receiptPrinter.render(LabelLayout(width: 100, height: 100) { Text("x") })
        }
    }
}
