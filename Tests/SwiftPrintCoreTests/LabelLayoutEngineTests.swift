//
//  LabelLayoutEngineTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

import Testing
@testable import SwiftPrintCore

/// Metrics where every character is 10 dots wide and a line 20 dots tall, so positions read as
/// arithmetic.
private struct GridMetrics: LabelMetrics {
    var dotsPerMillimeter: Double = 8
    var maximumWidth = 832
    var maximumHeight = 2000
    var maximumMagnification = 4

    func lineHeight(of font: PrintFont) -> Int? {
        font == .primary ? 20 : nil
    }

    func width(of character: Character, font: PrintFont) -> Int {
        10
    }
}

@Suite("Label layout")
struct LabelLayoutEngineTests {
    private static let all: PrintCapabilities = [.images, .qrCodes, .barcodes]

    private func layout(
        _ content: [PrintElement],
        width: PrintLength,
        height: PrintLength,
        metrics: GridMetrics = GridMetrics(),
        capabilities: PrintCapabilities = all
    ) throws(PrintError) -> LaidOutLabel {
        try LabelLayoutEngine(metrics: metrics, capabilities: capabilities)
            .layout(content, size: LabelSize(width: width, height: height))
    }

    private func text(_ string: String, _ alignment: PrintAlignment = .leading) -> PrintElement {
        .text([StyledRun(string)], alignment: alignment)
    }

    private func textElement(
        _ string: String,
        x: Int, y: Int, width: Int, height: Int = 20,
        _ alignment: PrintAlignment = .leading
    ) -> LabelElement {
        LabelElement(x: x, y: y, width: width, height: height, content: .text(StyledRun(string), alignment: alignment))
    }

    // MARK: - Size

    @Test("Millimetres are converted with the printer's resolution, each length rounded once")
    func physicalSize() throws {
        let at203 = try layout([], width: .millimeters(100), height: .millimeters(50))
        #expect((at203.width, at203.height) == (800, 400))
        let at300 = try layout(
            [], width: .millimeters(100), height: .millimeters(50),
            metrics: GridMetrics(dotsPerMillimeter: 300 / 25.4, maximumWidth: 1228)
        )
        #expect((at300.width, at300.height) == (1181, 591))
    }

    @Test("A label wider than the printhead or longer than the printer takes is refused")
    func printerLimits() {
        #expect(throws: PrintError(delivery: .notSent, reason: .exceedsPrinter(.width, dots: 840, maximum: 832))) {
            try layout([], width: .millimeters(105), height: .millimeters(50))
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .exceedsPrinter(.height, dots: 2400, maximum: 2000))) {
            try layout([], width: .millimeters(50), height: .millimeters(300))
        }
    }

    @Test("A dimension that is not a size is refused")
    func invalidDimensions() {
        #expect(throws: PrintError(delivery: .notSent, reason: .invalidDimension(.width, .dots(0)))) {
            try layout([], width: .dots(0), height: .millimeters(50))
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .invalidDimension(.height, .millimeters(-5)))) {
            try layout([], width: .millimeters(50), height: .millimeters(-5))
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .invalidDimension(.width, .inches(.infinity)))) {
            try layout([], width: .inches(.infinity), height: .millimeters(50))
        }
    }

    @Test("A label larger than the configured media is refused before any content is placed")
    func media() throws {
        let engine = { (media: LabelMedia) in
            LabelLayoutEngine(metrics: GridMetrics(), capabilities: Self.all, media: media)
        }
        let size = LabelSize(width: .millimeters(100), height: .millimeters(50))
        let tooTall: [PrintElement] = [.feed(lines: 100)]

        _ = try engine(LabelMedia(width: .millimeters(100), height: .millimeters(50))).layout([], size: size)
        _ = try engine(LabelMedia(width: .millimeters(102), height: nil)).layout([], size: size)
        #expect(throws: PrintError(delivery: .notSent, reason: .exceedsMedia(.width, dots: 800, media: 784))) {
            try engine(LabelMedia(width: .millimeters(98), height: nil)).layout(tooTall, size: size)
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .exceedsMedia(.height, dots: 400, media: 320))) {
            try engine(LabelMedia(width: .millimeters(100), height: .millimeters(40))).layout(tooTall, size: size)
        }
    }

    // MARK: - Text

    @Test("Padding insets the content, and each line is aligned by the printer within the width")
    func paddingAndAlignment() throws {
        let label = try layout(
            [.padding(PrintInsets(8), .verticalStack([text("AB"), text("CD", .center), text("EF", .trailing)], spacing: .zero))],
            width: .dots(320), height: .dots(160)
        )
        #expect(label.elements == [
            textElement("AB", x: 8, y: 8, width: 304),
            textElement("CD", x: 8, y: 28, width: 304, .center),
            textElement("EF", x: 8, y: 48, width: 304, .trailing),
        ])
    }

    @Test("Padding in millimetres follows the resolution")
    func physicalPadding() throws {
        let content: [PrintElement] = [.padding(PrintInsets(.millimeters(2)), text("A"))]
        let at203 = try layout(content, width: .millimeters(40), height: .millimeters(20))
        #expect(at203.elements.first.map { [$0.x, $0.y] } == [16, 16])
        let at300 = try layout(content, width: .millimeters(40), height: .millimeters(20), metrics: GridMetrics(dotsPerMillimeter: 300 / 25.4))
        #expect(at300.elements.first.map { [$0.x, $0.y] } == [24, 24])
    }

    @Test("Text wraps at spaces within the width")
    func wrapping() throws {
        let label = try layout([text("Product 1042 batch")], width: .dots(100), height: .dots(100))
        #expect(label.elements == [
            textElement("Product", x: 0, y: 0, width: 100),
            textElement("1042 batch", x: 0, y: 20, width: 100),
        ])
    }

    @Test("A line of several styles is placed run by run on a shared baseline")
    func mixedStyles() throws {
        let line = PrintElement.text(
            [StyledRun("AB"), StyledRun("C", style: TextStyle(size: .double))],
            alignment: .center
        )
        let label = try layout([line], width: .dots(320), height: .dots(160))
        #expect(label.elements == [
            textElement("AB", x: 140, y: 20, width: 20),
            LabelElement(x: 160, y: 0, width: 20, height: 40, content: .text(StyledRun("C", style: TextStyle(size: .double)), alignment: .leading)),
        ])
    }

    // MARK: - Stacks

    @Test("A spacer in a vertical stack takes the height left over")
    func verticalSpacer() throws {
        let label = try layout(
            [.verticalStack([text("A"), .spacer, text("B")], spacing: .dots(5))],
            width: .dots(100), height: .dots(100)
        )
        #expect(label.elements == [
            textElement("A", x: 0, y: 0, width: 100),
            textElement("B", x: 0, y: 80, width: 100),
        ])
    }

    @Test("Spacers share the height left over, the first ones taking the remainder")
    func sharedSpacers() throws {
        let label = try layout([text("A"), .spacer, text("B"), .spacer, text("C")], width: .dots(100), height: .dots(111))
        #expect(label.elements.map(\.y) == [0, 46, 91])
    }

    @Test("A spacer in a horizontal stack pushes what follows to the trailing edge")
    func horizontalSpacer() throws {
        let label = try layout(
            [.horizontalStack([text("Total"), .spacer, text("6,40")], alignment: .leading)],
            width: .dots(200), height: .dots(50)
        )
        #expect(label.elements == [
            textElement("Total", x: 0, y: 0, width: 50),
            textElement("6,40", x: 160, y: 0, width: 40),
        ])
    }

    @Test("Columns too wide for the label wrap the one before the spacer, as a receipt row does")
    func horizontalWrap() throws {
        let label = try layout(
            [.horizontalStack([text("Friet met saus"), .spacer, text("6,40")], alignment: .leading)],
            width: .dots(100), height: .dots(100)
        )
        #expect(label.elements == [
            textElement("Friet", x: 0, y: 0, width: 50),
            textElement("met", x: 0, y: 20, width: 50),
            textElement("saus", x: 0, y: 40, width: 50),
            textElement("6,40", x: 60, y: 0, width: 40),
        ])
    }

    @Test("A horizontal stack narrower than its space sits at its alignment")
    func horizontalAlignment() throws {
        let label = try layout(
            [.horizontalStack([text("AB"), text("CD")], alignment: .center)],
            width: .dots(100), height: .dots(50)
        )
        #expect(label.elements.map(\.x) == [25, 55])
    }

    // MARK: - Pictures and codes

    @Test("A QR code is as large as its modules and sits at its alignment")
    func qrCode() throws {
        let label = try layout(
            [.qrCode(PrintQRCode("AB", moduleSize: 4), alignment: .center)],
            width: .dots(100), height: .dots(100)
        )
        #expect(label.elements == [LabelElement(x: 8, y: 0, width: 84, height: 84, content: .qrCode(PrintQRCode("AB", moduleSize: 4)))])
    }

    @Test("A barcode's bars are as wide as its modules, with its text centred under them")
    func barcode() throws {
        let barcode = PrintBarcode("1042")
        let label = try layout([.barcode(barcode, alignment: .leading)], width: .dots(200), height: .dots(120))
        #expect(label.elements == [
            LabelElement(x: 0, y: 0, width: 158, height: 80, content: .barcode(barcode)),
            textElement("1042", x: 0, y: 85, width: 158, .center),
        ])
    }

    @Test("An image is placed one dot per pixel, scaled down to the width when wider")
    func image() throws {
        let image = PrintImage(width: 4, height: 2, pixels: [0, 255, 0, 255, 255, 0, 255, 0])!
        let label = try layout([.image(image, alignment: .trailing)], width: .dots(100), height: .dots(10))
        #expect(label.elements.map { [$0.x, $0.y, $0.width, $0.height] } == [[96, 0, 4, 2]])
    }

    @Test("A divider is a thin rule across the width, centred in a line")
    func divider() throws {
        let label = try layout([.divider("-", style: .plain)], width: .dots(100), height: .dots(20))
        #expect(label.elements == [LabelElement(x: 0, y: 9, width: 100, height: 2, content: .rule)])
    }

    // MARK: - Refusals

    @Test("Content taller than the label is refused, not cut off")
    func tooTall() {
        #expect(throws: PrintError(delivery: .notSent, reason: .contentOverflow("content 40 dots tall, in 30"))) {
            try layout([text("A"), text("B")], width: .dots(100), height: .dots(30))
        }
    }

    @Test("A code wider than its space is refused")
    func tooWide() {
        #expect(throws: PrintError(delivery: .notSent, reason: .contentOverflow("a QR code 126 dots wide, in 100"))) {
            try layout([.qrCode(PrintQRCode("AB"), alignment: .leading)], width: .dots(100), height: .dots(200))
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .contentOverflow("a barcode 158 dots wide, in 100"))) {
            try layout([.barcode(PrintBarcode("1042"), alignment: .leading)], width: .dots(100), height: .dots(200))
        }
    }

    @Test("Columns that leave no room for the flexible one are refused")
    func columnsOverflow() {
        #expect(throws: PrintError(delivery: .notSent, reason: .contentOverflow("columns 130 dots wide, in 60"))) {
            try layout([.horizontalStack([text("abcdefgh"), .spacer, text("123456")], alignment: .leading)], width: .dots(60), height: .dots(100))
        }
    }

    @Test("What the printer cannot do is refused rather than left off")
    func unsupported() {
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("QR codes, on this printer"))) {
            try layout([.qrCode(PrintQRCode("x"), alignment: .leading)], width: .dots(200), height: .dots(200), capabilities: [])
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("barcodes, on this printer"))) {
            try layout([.barcode(PrintBarcode("x"), alignment: .leading)], width: .dots(200), height: .dots(200), capabilities: [])
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("underlined text, on this printer"))) {
            try layout([.text([StyledRun("x", style: TextStyle(isUnderlined: true))], alignment: .leading)], width: .dots(200), height: .dots(200))
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .unsupported("text at 8×8; the printer magnifies at most 4×"))) {
            try layout([.text([StyledRun("x", style: TextStyle(size: TextSize(width: 8, height: 8)))], alignment: .leading)], width: .dots(200), height: .dots(200))
        }
    }

}

@Suite("Measurement")
struct MeasurementTests {
    @Test("Lengths convert to whole dots, halves away from zero")
    func lengths() {
        #expect(PrintLength.millimeters(10).dots(dotsPerMillimeter: 8, lineHeight: 20) == 80)
        #expect(PrintLength.millimeters(0.0625).dots(dotsPerMillimeter: 8, lineHeight: 20) == 1)
        #expect(PrintLength.inches(1).dots(dotsPerMillimeter: 8, lineHeight: 20) == 203)
        #expect(PrintLength.inches(1).dots(dotsPerMillimeter: 300 / 25.4, lineHeight: 20) == 300)
        #expect(PrintLength.lines(2).dots(dotsPerMillimeter: 8, lineHeight: 30) == 60)
        #expect(PrintLength.dots(7).dots(dotsPerMillimeter: 8, lineHeight: 30) == 7)
        #expect(PrintLength.millimeters(.infinity).dots(dotsPerMillimeter: 8, lineHeight: 30) == nil)
    }

    @Test("A QR code's size follows its payload and error correction")
    func qrCodeModules() {
        #expect(PrintQRCode("AB").moduleCount == 21)
        #expect(PrintQRCode(String(repeating: "x", count: 15)).moduleCount == 25)
        #expect(PrintQRCode(String(repeating: "x", count: 15), errorCorrection: .low).moduleCount == 21)
        #expect(PrintQRCode(String(repeating: "x", count: 2332)).moduleCount == nil)
    }

    @Test("A barcode's width follows its symbology and data")
    func barcodeModules() {
        #expect(PrintBarcode("1042").moduleCount == 79)
        #expect(PrintBarcode("AB", symbology: .code39).moduleCount == 63)
        #expect(PrintBarcode("590123412345", symbology: .ean13).moduleCount == 95)
    }
}
