//
//  PrinterTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import Testing
import SwiftPrint
import SwiftPrintTesting

private struct OrderReceipt: PrintDocument {
    var body: some PrintLayout {
        ReceiptLayout {
            Text("#42").size(.double).alignment(.center)
            HStack { Text("Friet"); Spacer(); Text("€ 3,20") }
        }
    }
}

@Suite("Printer")
struct PrinterTests {
    private let receipt = OrderReceipt()

    @Test("Printing renders, sends over the transport and reports the outcome")
    func prints() async throws {
        let transport = MockTransport()
        let printer = Printer(driver: MockDriver(columns: 16), transport: transport)

        let outcome = try await printer.print(receipt)

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
            try await printer.print(receipt)
        }
    }

    @Test("Responses are given in order and the last one repeats")
    func responseOrder() async throws {
        let refused = PrintError(delivery: .notSent, reason: .connectionRefused)
        let transport = MockTransport(responses: [.failure(refused), .success(.completionConfirmed)])
        let printer = Printer(driver: MockDriver(), transport: transport)

        await #expect(throws: refused) { try await printer.print(receipt) }
        #expect(try await printer.print(receipt).acknowledgement == .completionConfirmed)
        #expect(try await printer.print(receipt).acknowledgement == .completionConfirmed)
    }

    @Test("Degradations from layout reach the outcome")
    func degradations() async throws {
        let printer = Printer(driver: MockDriver(capabilities: []), transport: MockTransport())
        let outcome = try await printer.print(ReceiptLayout { QRCode("x") })
        #expect(outcome.degradations == [.qrCodeOmitted])
    }

    @Test("Without a transport a printer renders, and refuses to send or read status")
    func withoutTransport() async throws {
        let printer = Printer(
            driver: PlainTextReceiptDriver(),
            options: PrintOptions(receipt: ReceiptOptions(paperWidth: .millimeters58))
        )
        let rendered = try printer.render(receipt)
        #expect(String(decoding: rendered.bytes, as: UTF8.self).hasPrefix("             #42\n"))
        await #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("sending, without a transport"))) {
            try await printer.print(receipt)
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

    @Test("The same receipt is wrapped at the width of the paper configured for the job")
    func paperWidths() throws {
        let document = ReceiptLayout {
            HStack { Text("Stoofvlees met frietjes"); Spacer(); Text("€ 12,50") }
        }
        func text(_ paper: ReceiptPaperWidth) throws -> String {
            let printer = Printer(driver: PlainTextReceiptDriver(), options: PrintOptions(receipt: ReceiptOptions(paperWidth: paper)))
            return String(decoding: try printer.render(document).bytes, as: UTF8.self)
        }
        #expect(try text(.millimeters80) == "Stoofvlees met frietjes                  € 12,50\n")
        #expect(try text(.millimeters58) == "Stoofvlees met frietjes  € 12,50\n")
    }

    @Test("A label is laid out and rendered by a label driver")
    func label() throws {
        let printer = Printer(driver: MockDriver(textHeight: 20))
        let rendered = try printer.render(LabelLayout(width: .millimeters(20), height: .millimeters(10)) {
            Text("1042")
        })
        #expect(String(decoding: rendered.bytes, as: UTF8.self) == "0,0 160×20 text leading \"1042\"")
    }

    @Test("A layout the driver does not print is refused, never swapped for another")
    func unsupportedLayout() {
        let receiptPrinter = Printer(driver: PlainTextReceiptDriver())
        #expect(throws: PrintError(delivery: .notSent, reason: .layoutUnsupported(.label))) {
            try receiptPrinter.render(LabelLayout(width: 100, height: 100) { Text("x") })
        }
    }

    @Test("Errors say what is wrong and which setting caused it")
    func errorDescriptions() {
        let paper = PrintError(delivery: .notSent, reason: .paperWidthUnsupported(.millimeters58))
        #expect(paper.description == "The printer has no printable width for 58 mm paper, set in PrintOptions.receipt. Nothing was sent.")
        let media = PrintError(delivery: .notSent, reason: .exceedsMedia(.height, dots: 400, media: 240))
        #expect(media.description == "The label's height is 400 dots; the media set in PrintOptions.label is 240. Nothing was sent.")
    }
}
