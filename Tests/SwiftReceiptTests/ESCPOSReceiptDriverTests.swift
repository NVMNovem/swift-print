//
//  ESCPOSReceiptDriverTests.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

#if ESCPOS
import SwiftESCPOS
import Testing
@testable import SwiftReceipt

@Suite("ESC/POS driver")
struct ESCPOSReceiptDriverTests {
    private func printer(_ profile: ReceiptESCPOSProfile, paper: ReceiptPaperWidth = .millimeters80) -> ReceiptPrinter {
        ReceiptPrinter(
            connection: .tcp(host: "127.0.0.1"),
            driver: .escpos(profile: profile),
            options: PrintOptions(paperWidth: paper)
        )
    }

    private let receipt = VStack {
        Text("FrietHeus").bold().alignment(.center)
        HStack { Text("Totaal"); Spacer(); Text("€ 6,40") }
    }

    @Test("A receipt renders to the documented bytes on the generic profile")
    func genericBytes() throws {
        let rendered = try printer(.genericESCPOS).render(receipt)
        var expected: [UInt8] = [0x1B, 0x40]
        expected += [UInt8](repeating: 0x20, count: 19)
        expected += [0x1B, 0x45, 0x01]
        expected += Array("FrietHeus".utf8)
        expected += [0x0A, 0x1B, 0x45, 0x00]
        expected += Array("Totaal".utf8)
        expected += [UInt8](repeating: 0x20, count: 34)
        expected += Array("EUR 6,40".utf8)
        expected += [0x0A, 0x1B, 0x64, 0x03, 0x1D, 0x56, 0x01]
        #expect(rendered.bytes == expected)
        #expect(rendered.degradations == [.characterReplaced("€", with: "EUR")])
    }

    @Test("A profile with a euro code page selects it and prints € as one byte")
    func euroCodePage() throws {
        let rendered = try printer(.epsonTM).render(Text("€ 6,40"))
        #expect(Array(rendered.bytes.prefix(5)) == [0x1B, 0x40, 0x1B, 0x74, 19])
        #expect(Array(rendered.bytes.dropFirst(5).prefix(6)) == [0xD5, 0x20, 0x36, 0x2C, 0x34, 0x30])
        #expect(rendered.degradations.isEmpty)
    }

    @Test("Capabilities follow the profile")
    func capabilities() {
        #expect(printer(.genericESCPOS).capabilities == [.fullCut, .partialCut])
        #expect(printer(.epsonTM).capabilities == [.underline, .inverted, .secondaryFont, .images, .qrCodes, .fullCut, .partialCut, .status])
        #expect(printer(.duraposDPT201).capabilities == printer(.genericESCPOS).capabilities)
    }

    @Test("A QR code is drawn on a profile that has them and reported where it does not")
    func qrCode() throws {
        let epson = try printer(.epsonTM).render(QRCode("AB", moduleSize: 4))
        #expect(epson.bytes.contains(0x6B))
        #expect(epson.degradations.isEmpty)
        let generic = try printer(.genericESCPOS).render(QRCode("AB"))
        #expect(generic.degradations == [.qrCodeOmitted])
    }

    @Test("A paper width the profile lacks is refused before anything is sent")
    func paperWidth() {
        #expect(throws: ReceiptPrintError(delivery: .notSent, reason: .unsupported("58 mm paper on Epson TM series"))) {
            try printer(.epsonTM, paper: .millimeters58).render(receipt)
        }
    }

    @Test("Status is refused on a profile that cannot report it")
    func statusUnsupported() async {
        await #expect(throws: ReceiptPrintError(delivery: .notSent, reason: .unsupported("status on DURAPOS DPT201"))) {
            try await printer(.duraposDPT201).status()
        }
    }

    @Test("Connection failures keep their delivery exactly")
    func errorMapping() {
        let partial = ESCPOSConnectionError(delivery: .partiallySent(confirmedBytes: 4096), reason: .timedOut(.writing))
        #expect(ReceiptPrintError(partial) == ReceiptPrintError(delivery: .partiallySent(confirmedBytes: 4096), reason: .timedOut(.writing)))
        let refused = ESCPOSConnectionError(delivery: .notSent, reason: .connectionRefused)
        #expect(ReceiptPrintError(refused) == ReceiptPrintError(delivery: .notSent, reason: .connectionRefused))
    }

    @Test("Profiles are found by their persisted identifier")
    func profiles() {
        #expect(ReceiptESCPOSProfile(id: "durapos-dpt201") == .duraposDPT201)
        #expect(ReceiptESCPOSProfile(id: "nope") == nil)
    }
}
#endif
