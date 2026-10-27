//
//  ESCPOSDriverTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import SwiftESCPOS
import Testing
import SwiftPrint
@testable import SwiftPrintESCPOS

@Suite("ESC/POS driver")
struct ESCPOSDriverTests {
    private func printer(_ profile: ESCPOSProfile, paper: ReceiptPaperWidth = .millimeters80) -> Printer {
        Printer(driver: .escpos(profile: profile), options: PrintOptions(paperWidth: paper))
    }

    private let receipt = VStack {
        Text("FrietHeus").bold().alignment(.center)
        HStack { Text("Totaal"); Spacer(); Text("€ 6,40") }
    }

    @Test("A receipt renders to the documented bytes on the generic profile")
    func genericBytes() throws {
        let rendered = try printer(.generic).render(receipt)
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
        #expect(printer(.generic).capabilities == [.fullCut, .partialCut])
        #expect(printer(.epsonTM).capabilities == [.underline, .inverted, .secondaryFont, .images, .qrCodes, .fullCut, .partialCut, .status])
        #expect(printer(.duraposDPT201).capabilities == printer(.generic).capabilities)
    }

    @Test("A QR code is drawn on a profile that has them and reported where it does not")
    func qrCode() throws {
        let epson = try printer(.epsonTM).render(QRCode("AB", moduleSize: 4))
        #expect(epson.bytes.contains(0x6B))
        #expect(epson.degradations.isEmpty)
        let generic = try printer(.generic).render(QRCode("AB"))
        #expect(generic.degradations == [.qrCodeOmitted])
    }

    @Test("A raster image is sent as GS v 0 where the profile has images")
    func image() throws {
        let image = PrintImage(width: 8, height: 1, pixels: [0, 255, 0, 255, 0, 255, 0, 255])!
        let rendered = try printer(.epsonTM).render(Image(image))
        #expect(rendered.bytes.contains(0x76))
        #expect(rendered.degradations.isEmpty)
    }

    @Test("Barcodes, which swift-escpos does not draw, are left off and reported")
    func barcode() throws {
        let rendered = try printer(.epsonTM).render(Barcode("1042"))
        #expect(rendered.degradations == [.barcodeOmitted])
    }

    @Test("A label is refused by a receipt printer")
    func label() {
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("labels, with this driver"))) {
            try printer(.epsonTM).render(LabelLayout(width: .millimeters(50), height: .millimeters(30)) { Text("x") })
        }
    }

    @Test("A paper width the profile lacks is refused before anything is rendered")
    func paperWidth() {
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("58 mm paper on Epson TM series"))) {
            try printer(.epsonTM, paper: .millimeters58).render(receipt)
        }
    }

    @Test("A printer's status maps, paper end and every error flag included")
    func status() {
        var escpos = ESCPOSPrinterStatus()
        escpos.isOnline = true
        escpos.hasStoppedOnPaperEnd = true
        escpos.hasAutocutterError = true
        let status = PrinterStatus(escpos)
        #expect(status == PrinterStatus(isOnline: true, isPaperOut: true, hasError: true))
        #expect(status.isReady == false)
    }
}
