//
//  ReceiptPrinterTests.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import Testing
import SwiftReceipt
import SwiftReceiptTesting

@Suite("Receipt printer")
struct ReceiptPrinterTests {
    private let receipt = VStack {
        Text("#42").size(.double).alignment(.center)
        HStack { Text("Friet"); Spacer(); Text("€ 3,20") }
    }

    @Test("Printing renders, sends and reports the outcome")
    func prints() async throws {
        let driver = MockReceiptDriver(columns: 16)
        let printer = ReceiptPrinter(connection: .tcp(host: "printer.local"), driver: driver)

        let outcome = try await printer.print(ReceiptDocument(receipt))

        let sent = await driver.journal.sent
        #expect(sent.count == 1)
        #expect(String(decoding: sent[0].bytes, as: UTF8.self) == "     #42\nFriet     € 3,20")
        #expect(outcome.bytesSent == sent[0].bytes.count)
        #expect(outcome.acknowledgement == .none)
    }

    @Test("A failure keeps its delivery, so the caller can tell a retry is unsafe")
    func failureKeepsDelivery() async {
        let failure = ReceiptPrintError(delivery: .partiallySent(confirmedBytes: 12), reason: .disconnected(.writing))
        let printer = ReceiptPrinter(
            connection: .tcp(host: "printer.local"),
            driver: MockReceiptDriver(responses: [.failure(failure)])
        )
        await #expect(throws: failure) {
            try await printer.print(ReceiptDocument(receipt))
        }
    }

    @Test("Responses are given in order and the last one repeats")
    func responseOrder() async throws {
        let refused = ReceiptPrintError(delivery: .notSent, reason: .connectionRefused)
        let driver = MockReceiptDriver(responses: [.failure(refused), .success(.completionConfirmed)])
        let printer = ReceiptPrinter(connection: .tcp(host: "printer.local"), driver: driver)

        await #expect(throws: refused) { try await printer.print(ReceiptDocument(receipt)) }
        #expect(try await printer.print(ReceiptDocument(receipt)).acknowledgement == .completionConfirmed)
        #expect(try await printer.print(ReceiptDocument(receipt)).acknowledgement == .completionConfirmed)
    }

    @Test("Degradations from layout reach the outcome")
    func degradations() async throws {
        let printer = ReceiptPrinter(
            connection: .tcp(host: "printer.local"),
            driver: MockReceiptDriver(capabilities: [])
        )
        let outcome = try await printer.print(ReceiptDocument(QRCode("x")))
        #expect(outcome.degradations == [.qrCodeOmitted])
    }

    @Test("The plain-text driver renders and refuses to send")
    func plainText() async throws {
        let printer = ReceiptPrinter(
            connection: .tcp(host: "printer.local"),
            driver: PlainTextReceiptDriver(),
            options: PrintOptions(paperWidth: .millimeters58)
        )
        let rendered = try printer.render(receipt)
        #expect(String(decoding: rendered.bytes, as: UTF8.self).hasPrefix("             #42\n"))
        await #expect(throws: ReceiptPrintError(delivery: .notSent, reason: .unsupported("sending, with the plain-text driver"))) {
            try await printer.print(ReceiptDocument(receipt))
        }
    }
}
