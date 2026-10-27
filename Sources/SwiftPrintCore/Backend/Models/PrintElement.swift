//
//  PrintElement.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// One piece of a document, by meaning. Never a printer command.
///
/// Styles and alignment are already resolved: every run carries the style it prints in, and every
/// text, picture and code the alignment it sits at. The same elements are placed by either layout;
/// what a layout or printer cannot do is reported or refused there.
public indirect enum PrintElement: Sendable, Hashable {
    /// Text that wraps at the available width.
    case text([StyledRun], alignment: PrintAlignment)
    /// Flexible space. Between the columns of a ``horizontalStack(_:alignment:)`` it splits leading
    /// from trailing ones; in a label's ``verticalStack(_:spacing:)`` it takes the height left over.
    case spacer
    /// A line across the available width: the character repeated on a receipt, a rule on a label.
    case divider(Character, style: TextStyle)
    /// Empty lines.
    case feed(lines: Int)
    /// A picture, scaled down to the available width and dithered.
    case image(PrintImage, alignment: PrintAlignment)
    /// A QR code drawn by the printer.
    case qrCode(PrintQRCode, alignment: PrintAlignment)
    /// A linear barcode drawn by the printer.
    case barcode(PrintBarcode, alignment: PrintAlignment)
    /// Elements one under the other, `spacing` apart.
    case verticalStack([PrintElement], spacing: PrintLength)
    /// Elements side by side. On a receipt only text takes part, as the columns of one row; see
    /// ``ReceiptRow``. `alignment` places the stack when it is narrower than the space it has.
    case horizontalStack([PrintElement], alignment: PrintAlignment)
    /// An element with space around it.
    case padding(PrintInsets, PrintElement)
}
