//
//  TextMetrics.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How wide text is on one printer, after the printer's own character set has had its say.
///
/// Layout never counts `Character`s: a character a printer cannot hold may print as several
/// (`€` as `EUR`), and a double-width character takes twice the dots.
public protocol TextMetrics: Sendable {
    /// Printable dots per line.
    var lineWidth: Int { get }
    /// The largest magnification factor the printer takes.
    var maximumMagnification: Int { get }
    /// Dots per character cell at normal size, or `nil` when the printer lacks the font.
    func cellWidth(of font: ReceiptFont) -> Int?
    /// How many cells the character occupies at normal size once encoded.
    func cells(for character: Character) -> Int
}
