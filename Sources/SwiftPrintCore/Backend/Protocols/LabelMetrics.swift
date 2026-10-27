//
//  LabelMetrics.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// How one label printer measures: its resolution, its limits and the size of its text.
///
/// Text widths are what layout wraps and positions by. A driver whose printer draws a proportional
/// font answers widths no smaller than the widest the font draws, so a line laid out to fit does.
public protocol LabelMetrics: Sendable {
    /// Dots per millimetre.
    var dotsPerMillimeter: Double { get }
    /// The widest label the printhead covers, in dots.
    var maximumWidth: Int { get }
    /// The longest label the printer takes, in dots.
    var maximumHeight: Int { get }
    /// The largest magnification factor text takes.
    var maximumMagnification: Int { get }
    /// The height of a line in the font at normal size, in dots, or `nil` when the printer lacks
    /// the font.
    func lineHeight(of font: PrintFont) -> Int?
    /// The width the character takes in the font at normal size, in dots.
    func width(of character: Character, font: PrintFont) -> Int
}
