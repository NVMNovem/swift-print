//
//  LaidOutLabel.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// A label placed for one printer: its size and every element in its frame, all in dots measured
/// from the top-left corner, `x` to the right and `y` down.
public struct LaidOutLabel: Sendable, Hashable {
    /// The width in dots.
    public var width: Int
    /// The height in dots.
    public var height: Int
    /// The elements, top to bottom, then leading to trailing.
    public var elements: [LabelElement]

    public init(width: Int, height: Int, elements: [LabelElement]) {
        self.width = width
        self.height = height
        self.elements = elements
    }

    /// Every element and its frame, one per line, for previews, logs and tests.
    public var plainText: String {
        elements.map { element in
            let frame = "\(element.x),\(element.y) \(element.width)×\(element.height)"
            return switch element.content {
            case .text(let run, let alignment): "\(frame) text \(alignment) \"\(run.text)\""
            case .image: "\(frame) image"
            case .qrCode(let code): "\(frame) QR \(code.payload)"
            case .barcode(let barcode): "\(frame) barcode \(barcode.data)"
            case .rule: "\(frame) rule"
            }
        }
        .joined(separator: "\n")
    }
}

/// One thing on a laid-out label, in the frame it occupies.
public struct LabelElement: Sendable, Hashable {
    /// What is drawn.
    public enum Content: Sendable, Hashable {
        /// One line of text in one style, at `alignment` within the frame. The frame is as tall as a
        /// line at the run's size.
        case text(StyledRun, alignment: PrintAlignment)
        /// A picture, one dot per pixel, filling the frame.
        case image(PrintBitmap)
        /// A QR code whose modules fill the frame.
        case qrCode(PrintQRCode)
        /// A barcode's bars, filling the frame. Its text, when shown, is a separate text element.
        case barcode(PrintBarcode)
        /// A filled rectangle: a line as thick as the frame is tall.
        case rule
    }

    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int
    public var content: Content

    public init(x: Int, y: Int, width: Int, height: Int, content: Content) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.content = content
    }
}

/// A document placed by the layout its format names.
public enum LaidOutDocument: Sendable, Hashable {
    case receipt(LaidOutReceipt)
    case label(LaidOutLabel)
}
