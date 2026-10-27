//
//  LabelLayoutEngine.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// Places content on a label of a fixed size, for one label printer.
///
/// Everything is measured in the printer's dots: the label's size and every length are converted
/// once with the printer's resolution, then layout works in whole dots, so no rounding collects.
/// The content is a vertical stack filling the label. A vertical stack places its children one
/// under the other and gives any height left over to its spacers; a horizontal stack places them
/// side by side, gives width left over to its spacers and, when they are too wide, wraps the column
/// before its first spacer, as a receipt row does. Text wraps at the width it is given, with the
/// widths ``LabelMetrics`` answers. The same document and metrics always produce the same label.
///
/// A label cannot reflow, so nothing is degraded: content that does not fit, a style or code the
/// printer lacks, or a length that cannot be measured throws a ``PrintError``.
public struct LabelLayoutEngine: Sendable {
    /// How the printer measures.
    public let metrics: any LabelMetrics
    /// What the printer can do; anything else is refused.
    public let capabilities: PrintCapabilities
    /// The label stock configured for the printer, or `nil` when it is not known.
    public let media: LabelMedia?

    public init(metrics: any LabelMetrics, capabilities: PrintCapabilities, media: LabelMedia? = nil) {
        self.metrics = metrics
        self.capabilities = capabilities
        self.media = media
    }

    /// The content placed on a label of this size, or an error when the size does not suit the
    /// printer or its media, or the content does not fit.
    ///
    /// The size is checked before any content is placed: it must be a size, at most what the
    /// printer prints and, when ``media`` is known, at most the media's.
    public func layout(_ content: [PrintElement], size: LabelSize) throws(PrintError) -> LaidOutLabel {
        let context = try Context(metrics: metrics, capabilities: capabilities)
        let width = try checked(size.width, .width, maximum: metrics.maximumWidth, context: context)
        let height = try checked(size.height, .height, maximum: metrics.maximumHeight, context: context)
        let placed = try context.place(.verticalStack(content, spacing: .zero), width: width, height: height)
        return LaidOutLabel(width: width, height: height, elements: placed.elements)
    }

    /// One dimension of the label in dots, once it is known to be a size the printer and the media
    /// take.
    private func checked(
        _ length: PrintLength,
        _ dimension: PrintDimension,
        maximum: Int,
        context: Context
    ) throws(PrintError) -> Int {
        guard case let dots? = length.dots(dotsPerMillimeter: metrics.dotsPerMillimeter, lineHeight: context.lineHeight),
              dots > 0 else {
            throw PrintError(delivery: .notSent, reason: .invalidDimension(dimension, length))
        }
        guard dots <= maximum else {
            throw PrintError(delivery: .notSent, reason: .exceedsPrinter(dimension, dots: dots, maximum: maximum))
        }
        let mediaLength = switch dimension {
        case .width: media?.width
        case .height: media?.height
        }
        if let mediaLength {
            guard case let mediaDots? = mediaLength.dots(dotsPerMillimeter: metrics.dotsPerMillimeter, lineHeight: context.lineHeight),
                  mediaDots > 0 else {
                throw Self.unsupported("label media with a \(dimension) of \(mediaLength)")
            }
            guard dots <= mediaDots else {
                throw PrintError(delivery: .notSent, reason: .exceedsMedia(dimension, dots: dots, media: mediaDots))
            }
        }
        return dots
    }

    static func unsupported(_ description: String) -> PrintError {
        PrintError(delivery: .notSent, reason: .unsupported(description))
    }

    static func overflow(_ description: String) -> PrintError {
        PrintError(delivery: .notSent, reason: .contentOverflow(description))
    }
}

// MARK: - Context

extension LabelLayoutEngine {
    /// An element's size and its label elements, positioned from its own top-left corner.
    struct Placed {
        var width: Int
        var height: Int
        var elements: [LabelElement] = []

        func offset(x: Int, y: Int) -> [LabelElement] {
            elements.map { element in
                var element = element
                element.x += x
                element.y += y
                return element
            }
        }
    }

    struct Context {
        let metrics: any LabelMetrics
        let capabilities: PrintCapabilities
        /// The height of a line of plain text.
        let lineHeight: Int
        /// The width of a plain space: the gap between the columns of a horizontal stack.
        let spaceWidth: Int

        init(metrics: any LabelMetrics, capabilities: PrintCapabilities) throws(PrintError) {
            guard let lineHeight = metrics.lineHeight(of: .primary), lineHeight > 0 else {
                throw LabelLayoutEngine.unsupported("text, on a printer without a primary font")
            }
            self.metrics = metrics
            self.capabilities = capabilities
            self.lineHeight = lineHeight
            self.spaceWidth = max(1, metrics.width(of: " ", font: .primary))
        }

        // MARK: Placement

        /// The element at `width` dots, and at `height` when the height is fixed.
        func place(_ element: PrintElement, width: Int, height: Int?) throws(PrintError) -> Placed {
            switch element {
            case .text(let runs, let alignment):
                return try placeText(runs, alignment: alignment, width: width)
            case .spacer:
                return Placed(width: 0, height: height ?? 0)
            case .divider:
                let thickness = max(2, try dots(.millimeters(0.25), "a divider"))
                let rule = LabelElement(
                    x: 0, y: (lineHeight - thickness) / 2, width: width, height: thickness, content: .rule
                )
                return Placed(width: width, height: lineHeight, elements: [rule])
            case .feed(let lines):
                return Placed(width: 0, height: max(0, lines) * lineHeight)
            case .image(let image, _):
                try require(.images, "images")
                let bitmap = image.bitmap(width: min(image.width, width))
                return Placed(
                    width: bitmap.width,
                    height: bitmap.height,
                    elements: [LabelElement(x: 0, y: 0, width: bitmap.width, height: bitmap.height, content: .image(bitmap))]
                )
            case .qrCode(let code, _):
                try require(.qrCodes, "QR codes")
                let size = try qrCodeSize(code)
                guard size <= width else {
                    throw LabelLayoutEngine.overflow("a QR code \(size) dots wide, in \(width)")
                }
                return Placed(
                    width: size,
                    height: size,
                    elements: [LabelElement(x: 0, y: 0, width: size, height: size, content: .qrCode(code))]
                )
            case .barcode(let barcode, _):
                return try placeBarcode(barcode, width: width)
            case .verticalStack(let children, let spacing):
                return try placeVertically(children, spacing: spacing, width: width, height: height)
            case .horizontalStack(let children, _):
                return try placeHorizontally(children, width: width)
            case .padding(let insets, let child):
                let top = try dots(insets.top, "padding")
                let leading = try dots(insets.leading, "padding")
                let bottom = try dots(insets.bottom, "padding")
                let trailing = try dots(insets.trailing, "padding")
                guard top >= 0, leading >= 0, bottom >= 0, trailing >= 0 else {
                    throw LabelLayoutEngine.unsupported("negative padding")
                }
                let innerWidth = width - leading - trailing
                guard innerWidth > 0 else {
                    throw LabelLayoutEngine.overflow("padding of \(leading + trailing) dots across \(width)")
                }
                var innerHeight: Int?
                if let height {
                    innerHeight = height - top - bottom
                    guard innerHeight! >= 0 else {
                        throw LabelLayoutEngine.overflow("padding of \(top + bottom) dots along \(height)")
                    }
                }
                let placed = try place(child, width: innerWidth, height: innerHeight)
                return Placed(
                    width: placed.width + leading + trailing,
                    height: placed.height + top + bottom,
                    elements: placed.offset(x: leading, y: top)
                )
            }
        }

        // MARK: Stacks

        private func placeVertically(
            _ children: [PrintElement],
            spacing: PrintLength,
            width: Int,
            height: Int?
        ) throws(PrintError) -> Placed {
            let gap = try dots(spacing, "spacing")
            var placed: [Placed] = []
            for child in children {
                placed.append(try place(child, width: width, height: nil))
            }
            let natural = placed.reduce(0) { $0 + $1.height } + max(0, children.count - 1) * gap

            if let height {
                guard natural <= height else {
                    throw LabelLayoutEngine.overflow("content \(natural) dots tall, in \(height)")
                }
                let flexible = children.indices.filter { Self.isVerticallyFlexible(children[$0]) }
                if !flexible.isEmpty {
                    let extra = height - natural
                    for (order, index) in flexible.enumerated() {
                        let share = extra / flexible.count + (order < extra % flexible.count ? 1 : 0)
                        placed[index] = try place(children[index], width: width, height: placed[index].height + share)
                    }
                }
            }

            var elements: [LabelElement] = []
            var y = 0
            for (index, child) in placed.enumerated() {
                if index > 0 { y += gap }
                let x = Self.offset(of: child.width, in: width, alignment: Self.alignment(of: children[index]))
                elements += child.offset(x: x, y: y)
                y += child.height
            }
            return Placed(width: width, height: y, elements: elements)
        }

        private func placeHorizontally(_ children: [PrintElement], width: Int) throws(PrintError) -> Placed {
            let items = children.indices.filter { children[$0] != .spacer }
            guard !items.isEmpty else { return Placed(width: width, height: 0) }
            var widths: [Int: Int] = [:]
            for index in items {
                widths[index] = try idealWidth(children[index], within: width)
            }
            let total = items.reduce(0) { $0 + widths[$1]! } + (items.count - 1) * spaceWidth
            let spacers = children.indices.filter { children[$0] == .spacer }
            var extra = width - total

            if extra < 0 {
                // The column before the first spacer, or the last one, takes what the others leave.
                let firstSpacer = spacers.first ?? children.count
                let flexible = items.last { $0 < firstSpacer } ?? items[items.count - 1]
                let remaining = widths[flexible]! + extra
                guard remaining >= spaceWidth else {
                    throw LabelLayoutEngine.overflow("columns \(total) dots wide, in \(width)")
                }
                widths[flexible] = remaining
                extra = 0
            }

            var placed: [Int: Placed] = [:]
            for index in items {
                placed[index] = try place(children[index], width: widths[index]!, height: nil)
            }

            var elements: [LabelElement] = []
            var x = 0
            var spacerOrder = 0
            for index in children.indices {
                if children[index] == .spacer {
                    let share = extra / spacers.count + (spacerOrder < extra % spacers.count ? 1 : 0)
                    x += share
                    spacerOrder += 1
                    continue
                }
                if index != items[0] { x += spaceWidth }
                elements += placed[index]!.offset(x: x, y: 0)
                x += widths[index]!
            }
            let height = placed.values.map(\.height).max() ?? 0
            return Placed(width: spacers.isEmpty ? total : width, height: height, elements: elements)
        }

        /// The width an element takes when nothing constrains it, at most `limit`.
        private func idealWidth(_ element: PrintElement, within limit: Int) throws(PrintError) -> Int {
            let ideal: Int
            switch element {
            case .text(let runs, _):
                var widest = 0
                var current = 0
                for glyph in try glyphs(runs) {
                    if glyph.isLineBreak {
                        widest = max(widest, current)
                        current = 0
                    } else {
                        current += glyph.width
                    }
                }
                ideal = max(widest, current)
            case .spacer, .feed:
                ideal = 0
            case .divider:
                ideal = limit
            case .image(let image, _):
                ideal = image.width
            case .qrCode(let code, _):
                ideal = try qrCodeSize(code)
            case .barcode(let barcode, _):
                ideal = try barcodeWidths(barcode).total
            case .verticalStack(let children, _):
                var widest = 0
                for child in children {
                    widest = max(widest, try idealWidth(child, within: limit))
                }
                ideal = widest
            case .horizontalStack(let children, _):
                let items = children.filter { $0 != .spacer }
                var sum = max(0, items.count - 1) * spaceWidth
                for child in items {
                    sum += try idealWidth(child, within: limit)
                }
                ideal = children.contains(.spacer) ? max(sum, limit) : sum
            case .padding(let insets, let child):
                let sides = try dots(insets.leading, "padding") + dots(insets.trailing, "padding")
                ideal = try idealWidth(child, within: max(0, limit - sides)) + sides
            }
            return min(ideal, limit)
        }

        private static func isVerticallyFlexible(_ element: PrintElement) -> Bool {
            switch element {
            case .spacer: true
            case .verticalStack(let children, _): children.contains(where: isVerticallyFlexible)
            case .padding(_, let child): isVerticallyFlexible(child)
            default: false
            }
        }

        private static func alignment(of element: PrintElement) -> PrintAlignment {
            switch element {
            case .text(_, let alignment), .image(_, let alignment), .qrCode(_, let alignment),
                 .barcode(_, let alignment), .horizontalStack(_, let alignment):
                alignment
            case .padding(_, let child):
                alignment(of: child)
            case .spacer, .divider, .feed, .verticalStack:
                .leading
            }
        }

        private static func offset(of width: Int, in available: Int, alignment: PrintAlignment) -> Int {
            switch alignment {
            case .leading: 0
            case .center: max(0, available - width) / 2
            case .trailing: max(0, available - width)
            }
        }

        // MARK: Text

        /// Text wrapped at `width`. A line in one style is one element as wide as the text has, at
        /// its alignment, so the printer aligns it with its own glyph widths; a line of several
        /// styles is one element per run, placed by measured width on a shared baseline.
        private func placeText(_ runs: [StyledRun], alignment: PrintAlignment, width: Int) throws(PrintError) -> Placed {
            var elements: [LabelElement] = []
            var y = 0
            for line in try glyphs(runs).wrapped(toWidth: width) {
                let lineRuns = line.runs
                let height = try lineRuns.map { run throws(PrintError) in try self.height(of: run.style) }.max() ?? lineHeight
                if lineRuns.count == 1 {
                    elements.append(LabelElement(
                        x: 0, y: y, width: width, height: height, content: .text(lineRuns[0], alignment: alignment)
                    ))
                } else {
                    var x = Self.offset(of: line.width, in: width, alignment: alignment)
                    var start = line.startIndex
                    for run in lineRuns {
                        let end = start + run.text.count
                        let runWidth = Array(line[start..<end]).width
                        let runHeight = try self.height(of: run.style)
                        elements.append(LabelElement(
                            x: x, y: y + height - runHeight, width: runWidth, height: runHeight,
                            content: .text(run, alignment: .leading)
                        ))
                        x += runWidth
                        start = end
                    }
                }
                y += height
            }
            return Placed(width: width, height: y, elements: elements)
        }

        private func glyphs(_ runs: [StyledRun]) throws(PrintError) -> [Glyph] {
            var glyphs: [Glyph] = []
            for run in runs {
                try checkPrintable(run.style)
                for character in run.text {
                    let width = character == "\n" || character == "\r\n"
                        ? 0
                        : metrics.width(of: character, font: run.style.font) * run.style.size.width
                    glyphs.append(Glyph(character: character, style: run.style, width: width))
                }
            }
            return glyphs
        }

        private func height(of style: TextStyle) throws(PrintError) -> Int {
            guard let height = metrics.lineHeight(of: style.font) else {
                throw LabelLayoutEngine.unsupported("the secondary font, on this printer")
            }
            return height * style.size.height
        }

        /// Refuses a style the printer cannot print, rather than printing it differently.
        private func checkPrintable(_ style: TextStyle) throws(PrintError) {
            if style.isUnderlined, !capabilities.contains(.underline) {
                throw LabelLayoutEngine.unsupported("underlined text, on this printer")
            }
            if style.isInverted, !capabilities.contains(.inverted) {
                throw LabelLayoutEngine.unsupported("inverted text, on this printer")
            }
            if style.font == .secondary,
               !capabilities.contains(.secondaryFont) || metrics.lineHeight(of: .secondary) == nil {
                throw LabelLayoutEngine.unsupported("the secondary font, on this printer")
            }
            let maximum = max(1, metrics.maximumMagnification)
            if style.size.width > maximum || style.size.height > maximum {
                throw LabelLayoutEngine.unsupported(
                    "text at \(style.size.width)×\(style.size.height); the printer magnifies at most \(maximum)×"
                )
            }
        }

        // MARK: Codes

        private func qrCodeSize(_ code: PrintQRCode) throws(PrintError) -> Int {
            guard let modules = code.moduleCount else {
                throw LabelLayoutEngine.overflow("a QR code payload of \(code.payload.utf8.count) bytes")
            }
            guard code.moduleSize > 0 else {
                throw LabelLayoutEngine.unsupported("a QR code of \(code.moduleSize) dots per module")
            }
            return modules * code.moduleSize
        }

        /// The bars' width, and the width of the bars and their text together.
        private func barcodeWidths(_ barcode: PrintBarcode) throws(PrintError) -> (bars: Int, total: Int) {
            guard barcode.moduleWidth > 0 else {
                throw LabelLayoutEngine.unsupported("a barcode of \(barcode.moduleWidth) dots per module")
            }
            let bars = barcode.moduleCount * barcode.moduleWidth
            guard barcode.showsText else { return (bars, bars) }
            return (bars, max(bars, try glyphs([StyledRun(barcode.data)]).width))
        }

        /// The bars, with their text centred under them when shown.
        private func placeBarcode(_ barcode: PrintBarcode, width: Int) throws(PrintError) -> Placed {
            try require(.barcodes, "barcodes")
            let (bars, total) = try barcodeWidths(barcode)
            guard total <= width else {
                throw LabelLayoutEngine.overflow("a barcode \(total) dots wide, in \(width)")
            }
            let barHeight = try dots(barcode.height, "a barcode's height")
            guard barHeight > 0 else {
                throw LabelLayoutEngine.unsupported("a barcode \(barHeight) dots tall")
            }
            var elements = [LabelElement(
                x: (total - bars) / 2, y: 0, width: bars, height: barHeight, content: .barcode(barcode)
            )]
            var height = barHeight
            if barcode.showsText {
                height += lineHeight / 4
                elements.append(LabelElement(
                    x: 0, y: height, width: total, height: lineHeight,
                    content: .text(StyledRun(barcode.data), alignment: .center)
                ))
                height += lineHeight
            }
            return Placed(width: total, height: height, elements: elements)
        }

        // MARK: Values

        private func require(_ capability: PrintCapabilities, _ description: String) throws(PrintError) {
            guard capabilities.contains(capability) else {
                throw LabelLayoutEngine.unsupported("\(description), on this printer")
            }
        }

        func dots(_ length: PrintLength, _ description: String) throws(PrintError) -> Int {
            guard let dots = length.dots(dotsPerMillimeter: metrics.dotsPerMillimeter, lineHeight: lineHeight) else {
                throw LabelLayoutEngine.unsupported("\(description) of \(length)")
            }
            return dots
        }
    }
}
