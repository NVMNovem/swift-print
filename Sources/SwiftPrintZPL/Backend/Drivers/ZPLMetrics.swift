//
//  ZPLMetrics.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// How a ZPL printer measures: resolution and limits from the profile, text in the scalable font.
///
/// The scalable font is proportional and the printer does not report its widths, so a character's
/// width is an upper estimate by its shape, as a share of the text height: wide letters 0.8,
/// capitals and digits 0.65, everything else 0.55. Layout wraps by these widths, so a line it lays
/// out fits on paper; the printer aligns each line itself, with its own widths. The shares are
/// estimates until checked on a printer.
struct ZPLMetrics: LabelMetrics {
    let profile: ZPLProfile
    /// The height of plain text, in dots.
    let textHeight: Int

    var dotsPerMillimeter: Double {
        profile.resolution.dotsPerMillimeter
    }

    var maximumWidth: Int {
        profile.maximumPrintWidth
    }

    var maximumHeight: Int {
        profile.maximumLabelLength
    }

    /// As far as a field's height, at most 32000 dots, allows.
    var maximumMagnification: Int {
        max(1, 32000 / textHeight)
    }

    func lineHeight(of font: PrintFont) -> Int? {
        font == .primary ? textHeight : nil
    }

    func width(of character: Character, font: PrintFont) -> Int {
        let share: Int = if Self.wide.contains(character) {
            80
        } else if character.isUppercase || character.isNumber {
            65
        } else {
            55
        }
        return (textHeight * share + 99) / 100
    }

    private static let wide: Set<Character> = ["M", "W", "m", "w", "@", "%", "Æ", "æ", "Œ", "œ"]
}
