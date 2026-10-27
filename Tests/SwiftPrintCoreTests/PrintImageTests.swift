//
//  PrintImageTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

import Testing
@testable import SwiftPrintCore

@Suite("Images")
struct ReceiptImageTests {
    @Test("Black and white pixels dither to themselves")
    func blackAndWhite() {
        let image = PrintImage(width: 4, height: 1, pixels: [0, 255, 0, 255])!
        let bitmap = image.bitmap(width: 4)
        #expect(bitmap.packedRows == [0b1010_0000])
    }

    @Test("Mid-grey dithers to a pattern of about half the dots")
    func grey() {
        let image = PrintImage(width: 16, height: 16, pixels: [UInt8](repeating: 128, count: 256))!
        let bitmap = image.bitmap(width: 16)
        let dots = (0..<16).flatMap { y in (0..<16).map { x in bitmap.isDot(x: x, y: y) } }.filter { $0 }.count
        #expect((96...160).contains(dots))
    }

    @Test("Scaling keeps the proportions and the same image gives the same dots")
    func scaling() {
        let pixels = (0..<(40 * 20)).map { UInt8(($0 * 7) % 256) }
        let image = PrintImage(width: 40, height: 20, pixels: pixels)!
        let first = image.bitmap(width: 20)
        #expect(first.width == 20)
        #expect(first.height == 10)
        #expect(first == image.bitmap(width: 20))
    }

    @Test("A pixel count that does not match the size is refused")
    func mismatch() {
        #expect(PrintImage(width: 2, height: 2, pixels: [0, 0, 0]) == nil)
    }
}
