//
//  Barcode.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// A linear barcode drawn by the printer, with its data in text under the bars. Left off, and
/// reported, on a receipt printer without barcodes; refused on a label printer without them.
public struct Barcode: PrintContent {
    let barcode: PrintBarcode

    /// A barcode holding `data`.
    ///
    /// - Parameters:
    ///   - symbology: How the data is drawn; the driver checks the data against it.
    ///   - height: The height of the bars.
    ///   - moduleWidth: Dots per narrow bar.
    ///   - showsText: Whether the data is printed under the bars.
    public init(
        _ data: String,
        symbology: PrintBarcode.Symbology = .code128,
        height: PrintLength = .millimeters(10),
        moduleWidth: Int = 2,
        showsText: Bool = true
    ) {
        self.barcode = PrintBarcode(
            data, symbology: symbology, height: height, moduleWidth: moduleWidth, showsText: showsText
        )
    }

    public var body: Never {
        return fatalError("Barcode has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.barcode(barcode)])
    }
}
