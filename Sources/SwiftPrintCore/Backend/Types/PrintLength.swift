//
//  PrintLength.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// A distance on the paper: in printer dots, a physical unit, or lines of text.
///
/// Layout works in whole dots. A physical length is converted with the printer's resolution and
/// rounded once, to the nearest dot with halves away from zero — at 8 dots/mm `.millimeters(10)` is
/// 80 dots — so a length never collects the rounding of others. A line is the height of one line of
/// plain text on the printer.
///
/// An integer literal is a number of dots.
public enum PrintLength: Sendable, Hashable, ExpressibleByIntegerLiteral {
    case dots(Int)
    case millimeters(Double)
    case inches(Double)
    /// Lines of plain text.
    case lines(Int)

    /// No distance.
    public static let zero = PrintLength.dots(0)

    public init(integerLiteral value: Int) {
        self = .dots(value)
    }

    /// The length in whole dots, or `nil` when it is not a finite number or too large to count.
    ///
    /// - Parameters:
    ///   - dotsPerMillimeter: The printer's resolution.
    ///   - lineHeight: The height of a line of plain text, in dots.
    public func dots(dotsPerMillimeter: Double, lineHeight: Int) -> Int? {
        switch self {
        case .dots(let dots):
            dots
        case .millimeters(let millimeters):
            Self.wholeDots(millimeters * dotsPerMillimeter)
        case .inches(let inches):
            Self.wholeDots(inches * 25.4 * dotsPerMillimeter)
        case .lines(let lines):
            lines.multipliedReportingOverflow(by: lineHeight).overflow ? nil : lines * lineHeight
        }
    }

    private static func wholeDots(_ value: Double) -> Int? {
        let rounded = value.rounded(.toNearestOrAwayFromZero)
        guard rounded.isFinite, rounded.magnitude < 1e15 else { return nil }
        return Int(rounded)
    }
}

/// Space on each side of an element.
public struct PrintInsets: Sendable, Hashable {
    public var top: PrintLength
    public var leading: PrintLength
    public var bottom: PrintLength
    public var trailing: PrintLength

    public init(
        top: PrintLength = .zero,
        leading: PrintLength = .zero,
        bottom: PrintLength = .zero,
        trailing: PrintLength = .zero
    ) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    /// The same space on every side.
    public init(_ length: PrintLength) {
        self.init(top: length, leading: length, bottom: length, trailing: length)
    }

    /// Whether every side is a length of zero.
    public var isZero: Bool {
        [top, leading, bottom, trailing].allSatisfy(\.isZero)
    }
}

extension PrintLength {
    /// Whether the length is zero, in any unit.
    public var isZero: Bool {
        switch self {
        case .dots(let value), .lines(let value): value == 0
        case .millimeters(let value), .inches(let value): value == 0
        }
    }
}
