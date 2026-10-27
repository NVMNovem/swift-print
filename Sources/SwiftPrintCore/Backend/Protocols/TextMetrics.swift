//
//  TextMetrics.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How wide text is on one receipt printer, after the printer's own character set has had its say.
///
/// Layout never counts `Character`s: a character a printer cannot hold may print as several
/// (`€` as `EUR`), and a double-width character takes twice the dots.
public protocol TextMetrics: Sendable {
    /// Printable dots per line.
    var lineWidth: Int { get }
    /// The largest magnification factor the printer takes.
    var maximumMagnification: Int { get }
    /// Dots per millimetre along the paper, for spacing given in a physical unit.
    var dotsPerMillimeter: Double { get }
    /// Dots one line feed advances, for spacing given in a physical unit.
    var lineHeight: Int { get }
    /// Dots per character cell at normal size, or `nil` when the printer lacks the font.
    func cellWidth(of font: PrintFont) -> Int?
    /// How many cells the character occupies at normal size once encoded.
    func cells(for character: Character) -> Int
}

extension TextMetrics {
    /// 8 dots/mm, the 203 dpi of most receipt printers.
    public var dotsPerMillimeter: Double { 8 }
    /// 30 dots, the usual default line spacing at 203 dpi.
    public var lineHeight: Int { 30 }
}
