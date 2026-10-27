//
//  PrintBarcode.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// A linear barcode, by meaning. The driver draws it with the printer's own command, and checks
/// the data against the symbology when it renders.
public struct PrintBarcode: Sendable, Hashable {
    /// How the data is drawn as bars.
    public enum Symbology: Sendable, Hashable, CaseIterable {
        /// Code 128: printable ASCII.
        case code128
        /// Code 39: digits, upper-case letters, space and `- . $ / + %`.
        case code39
        /// EAN-13: twelve digits, or thirteen with the check digit.
        case ean13
    }

    /// The data the bars hold.
    public var data: String
    public var symbology: Symbology
    /// The height of the bars.
    public var height: PrintLength
    /// Dots per narrow bar.
    public var moduleWidth: Int
    /// Whether the data is printed in text under the bars.
    public var showsText: Bool

    public init(
        _ data: String,
        symbology: Symbology = .code128,
        height: PrintLength = .millimeters(10),
        moduleWidth: Int = 2,
        showsText: Bool = true
    ) {
        self.data = data
        self.symbology = symbology
        self.height = height
        self.moduleWidth = moduleWidth
        self.showsText = showsText
    }

    /// The width of the bars in modules, quiet zones excluded — for Code 128 the most it can take,
    /// as if every character needed its own symbol, so a printer that packs digits draws narrower.
    public var moduleCount: Int {
        let count = data.count
        switch symbology {
        case .code128:
            // Start, a symbol per character, the check symbol, each 11 modules; the stop is 13.
            return 11 * (count + 2) + 13
        case .code39:
            // Start and stop around the data; 9 elements, 3 of them wide at a 3:1 ratio, are 15
            // modules, with a one-module gap between characters.
            let characters = count + 2
            return characters * 15 + characters - 1
        case .ean13:
            return 95
        }
    }
}
