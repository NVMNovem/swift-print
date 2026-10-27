//
//  LabelDSLTests.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

import Testing
import SwiftPrint
import SwiftPrintTesting

private struct ProductLabel: PrintDocument {
    let number: String
    let batch: String

    var body: some PrintLayout {
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

private struct ProductDetails: PrintContent {
    var body: some PrintContent {
        VStack { Text("Product"); Barcode("123456") }
    }
}

@Suite("Label DSL")
struct LabelDSLTests {
    @Test("A label layout makes a label document of its size")
    func format() {
        let document = ResolvedDocument(ProductLabel(number: "1042", batch: "A-2026"))
        #expect(document.format == .label(LabelSize(width: .millimeters(100), height: .millimeters(50))))
        #expect(document.content == [
            .padding(PrintInsets(8), .verticalStack([
                .text([StyledRun("Product 1042", style: TextStyle(size: .double))], alignment: .leading),
                .text([StyledRun("Batch A-2026")], alignment: .leading),
                .spacer,
                .barcode(PrintBarcode("1042"), alignment: .leading),
            ], spacing: 4)),
        ])
    }

    @Test("The same content resolves the same in either layout")
    func sameContent() {
        let label = ResolvedDocument(LabelLayout(width: 400, height: 200) { ProductDetails() })
        let receipt = ResolvedDocument(ReceiptLayout { ProductDetails() })
        #expect(receipt.format == .receipt)
        #expect(label.content == receipt.content)
    }

    @Test("A realistic 100 × 50 mm product label is laid out within its size")
    func productLabel() throws {
        let printer = Printer(driver: MockDriver(textHeight: 24))
        guard case .label(let label) = try printer.layout(ProductLabel(number: "1042", batch: "A-2026")) else {
            Issue.record("Not a label.")
            return
        }
        #expect((label.width, label.height) == (800, 400))
        #expect(label.plainText == """
        8,8 784×48 text leading "Product 1042"
        8,60 784×24 text leading "Batch A-2026"
        8,282 158×80 barcode 1042
        8,368 158×24 text center "1042"
        """)
    }

    @Test("A label that fits the configured media prints; one larger than it is refused")
    func media() throws {
        func printer(_ media: LabelMedia) -> Printer {
            Printer(driver: MockDriver(textHeight: 24), options: PrintOptions(label: LabelOptions(media: media)))
        }
        let label = ProductLabel(number: "1042", batch: "A-2026")
        _ = try printer(LabelMedia(width: .millimeters(100), height: .millimeters(50))).render(label)
        _ = try printer(LabelMedia(width: .millimeters(104), height: nil)).render(label)
        #expect(throws: PrintError(delivery: .notSent, reason: .exceedsMedia(.height, dots: 400, media: 240))) {
            try printer(LabelMedia(width: .millimeters(100), height: .millimeters(30))).render(label)
        }
        #expect(throws: PrintError(delivery: .notSent, reason: .exceedsMedia(.width, dots: 800, media: 400))) {
            try printer(LabelMedia(width: .millimeters(50), height: nil)).render(label)
        }
    }

    @Test("Padding on a receipt is left off and reported")
    func paddingOnReceipt() throws {
        let printer = Printer(driver: MockDriver(columns: 8))
        let rendered = try printer.render(ReceiptLayout { Text("a").padding(8) })
        #expect(rendered.degradations == [.paddingIgnored])
    }
}
