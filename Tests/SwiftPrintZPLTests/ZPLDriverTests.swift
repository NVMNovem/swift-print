//
//  ZPLDriverTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

import SwiftZPL
import Testing
import SwiftPrint
@testable import SwiftPrintZPL

private struct ProductLabel: PrintContent {
    let number: String
    let batch: String

    var body: some PrintContent {
        LabelLayout(width: .millimeters(100), height: .millimeters(50)) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Product \(number)").size(.double)
                Text("Batch \(batch)")
                Spacer()
                Barcode(number)
            }
            .padding(8)
        }
    }
}

@Suite("ZPL driver")
struct ZPLDriverTests {
    private func printer(_ profile: ZPLProfile = .zebraZD420d203) -> Printer {
        Printer(driver: .zpl(profile: profile))
    }

    private func zpl(_ content: some PrintContent, on printer: Printer) throws(PrintError) -> String {
        String(decoding: try printer.render(content).bytes, as: UTF8.self)
    }

    private func small<Content: PrintContent>(@PrintBuilder _ content: () -> Content) -> LabelLayout {
        LabelLayout(width: .millimeters(50), height: .millimeters(25), content: content)
    }

    @Test("A text label sets its size and places the text as a one-line field block")
    func text() throws {
        #expect(try zpl(small { Text("Hi") }, on: printer())
            == "^XA^CI28^PW400^LL200^FO0,0^A0N,30,30^FB400,1,0,L,0^FDHi^FS^XZ")
    }

    @Test("A 100 × 50 mm product label at 203 dpi")
    func productLabel() throws {
        let zpl = try zpl(ProductLabel(number: "1042", batch: "A-2026"), on: printer())
        #expect(zpl == [
            "^XA^CI28^PW800^LL400",
            "^FO8,8^A0N,60,60^FB784,1,0,L,0^FDProduct 1042^FS",
            "^FO8,72^A0N,30,30^FB784,1,0,L,0^FDBatch A-2026^FS",
            "^FO8,275^BY2^BCN,80,N,N,N,A^FD1042^FS",
            "^FO8,362^A0N,30,30^FB158,1,0,C,0^FD1042^FS",
            "^XZ",
        ].joined())
    }

    @Test("The same label at 300 dpi keeps its physical size")
    func productLabelAt300() throws {
        let zpl = try zpl(ProductLabel(number: "1042", batch: "A-2026"), on: printer(.zebraZD420d300))
        #expect(zpl.hasPrefix("^XA^CI28^PW1181^LL591^FO8,8^A0N,88,88^"))
        #expect(zpl.contains("^BY2^BCN,118,N,N,N,A^FD1042^FS"))
    }

    @Test("The same label renders to the same bytes")
    func deterministic() throws {
        let label = ProductLabel(number: "1042", batch: "A-2026")
        #expect(try printer().render(label) == printer().render(label))
    }

    @Test("The label is built from swift-zpl's model, with the driver's setup first")
    func labelModel() throws {
        let driver = ZPLDriver(profile: .zebraZD420d203, setup: [.mediaTracking(.gap)], quantity: 2)
        let printer = Printer(driver: driver)
        guard case .label(let laidOut) = try printer.layout(PrintDocument(small { Text("Hi") })) else {
            Issue.record("Not a label.")
            return
        }
        let label = try driver.label(for: laidOut)
        #expect(label.commands.prefix(3) == [.mediaTracking(.gap), .printWidth(.dots(400)), .labelLength(.dots(200))])
        #expect(label.quantity == 2)
        #expect(try zpl(small { Text("Hi") }, on: printer).hasSuffix("^PQ2^XZ"))
    }

    @Test("A QR code is drawn with the profile's QR command")
    func qrCode() throws {
        #expect(try zpl(small { QRCode("AB", moduleSize: 4) }, on: printer())
            == "^XA^CI28^PW400^LL200^FO0,0^BQN,2,4^FDMA,AB^FS^XZ")
    }

    @Test("A divider is a filled box across the width")
    func divider() throws {
        #expect(try zpl(small { Divider() }, on: printer())
            == "^XA^CI28^PW400^LL200^FO0,14^GB400,2,2,B,0^FS^XZ")
    }

    @Test("An image is sent as a graphic field")
    func image() throws {
        let image = PrintImage(width: 8, height: 1, pixels: [0, 255, 0, 255, 0, 255, 0, 255])!
        #expect(try zpl(small { Image(image) }, on: printer())
            == "^XA^CI28^PW400^LL200^FO0,0^GFA,1,1,1,AA^FS^XZ")
    }

    @Test("What the profile lacks is refused, never left off")
    func unsupported() {
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("QR codes, on this printer"))) {
            try printer(.generic).render(small { QRCode("AB") })
        }
        let image = PrintImage(width: 1, height: 1, pixels: [0])!
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("images, on this printer"))) {
            try printer(.generic).render(small { Image(image) })
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("underlined text, on this printer"))) {
            try printer().render(small { Text("x").underline() })
        }
    }

    @Test("A label wider than the printhead is refused")
    func tooWide() {
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("a label 880 dots wide; the printer prints at most 832"))) {
            try printer().render(LabelLayout(width: .millimeters(110), height: .millimeters(50)) { Text("x") })
        }
    }

    @Test("Content too tall for the label is refused")
    func tooTall() {
        #expect(throws: PrintError(delivery: .notSent, reason: .contentOverflow("content 240 dots tall, in 200"))) {
            try printer().render(small { ForEach(0..<8) { Text("Line \($0)") } })
        }
    }

    @Test("Data the encoder refuses fails rendering with its reason")
    func encoderErrors() {
        #expect(throws: PrintError(delivery: .notSent, reason: .renderingFailed(String(describing: ZPLEncodingError.unencodableCharacter("é", .usa1))))) {
            try printer(.generic).render(small { Text("é") })
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .renderingFailed(String(describing: ZPLEncodingError.invalidBarcodeData(.ean13, .invalidCharacter("A")))))) {
            try printer().render(small { Barcode("A12345678901", symbology: .ean13) })
        }
    }

    @Test("A receipt is refused by a label printer")
    func receipt() {
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("receipts, with this driver"))) {
            try printer().render(Text("x"))
        }
    }

    @Test("Capabilities follow the profile")
    func capabilities() {
        #expect(printer(.generic).capabilities == [.barcodes])
        #expect(printer().capabilities == [.barcodes, .images, .qrCodes, .status])
    }

    @Test("A host status maps onto the printer status")
    func status() {
        #expect(PrinterStatus(ZPLHostStatus()) == PrinterStatus(isOnline: true, isCoverOpen: false, isPaperOut: false, hasError: false))
        #expect(PrinterStatus(ZPLHostStatus()).isReady == true)
        #expect(PrinterStatus(ZPLHostStatus(isPaused: true, isHeadUp: true)).isReady == false)
        #expect(PrinterStatus(ZPLHostStatus(isRibbonOut: true)).hasError == false)
        #expect(PrinterStatus(ZPLHostStatus(isRibbonOut: true, isThermalTransferMode: true)).hasError == true)
    }
}
