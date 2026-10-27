//
//  ReceiptLayoutEngine.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Places content on the paper of one receipt printer: line after line, as long as it needs.
///
/// A receipt is a grid of character cells, so this is a column layout, not a layout engine: text
/// wraps at spaces, a row keeps its fixed columns and wraps its flexible one, and alignment pads
/// with plain spaces. Everything is measured in the printer's dots through ``TextMetrics``, so a
/// double-width character or a character printed as three is accounted for. The same document and
/// metrics always produce the same lines.
///
/// Elements are first lowered to ``ReceiptBlock``s: a vertical stack becomes its blocks with blank
/// lines between them, a horizontal stack one ``ReceiptRow``. What a receipt cannot place — padding,
/// or a style or picture the printer lacks — is left off and reported.
public struct ReceiptLayoutEngine: Sendable {
    /// How wide text is on the printer.
    public let metrics: any TextMetrics
    /// What the printer can do; anything else is degraded.
    public let capabilities: PrintCapabilities

    public init(metrics: any TextMetrics, capabilities: PrintCapabilities) {
        self.metrics = metrics
        self.capabilities = capabilities
    }

    /// The content's lines on this paper, and everything printed differently.
    public func layout(_ content: [PrintElement]) -> LaidOutReceipt {
        var context = Context(metrics: metrics, capabilities: capabilities)
        for block in context.blocks(content) {
            context.place(block)
        }
        return LaidOutReceipt(lines: context.lines, degradations: context.degradations)
    }

    /// The blocks' lines on this paper, and everything printed differently.
    public func layout(_ blocks: [ReceiptBlock]) -> LaidOutReceipt {
        var context = Context(metrics: metrics, capabilities: capabilities)
        for block in blocks {
            context.place(block)
        }
        return LaidOutReceipt(lines: context.lines, degradations: context.degradations)
    }

    /// The blocks the elements lower to, and everything left off on the way.
    public func blocks(_ elements: [PrintElement]) -> (blocks: [ReceiptBlock], degradations: [PrintDegradation]) {
        var context = Context(metrics: metrics, capabilities: capabilities)
        let blocks = context.blocks(elements)
        return (blocks, context.degradations)
    }
}

// MARK: - Context

extension ReceiptLayoutEngine {
    struct Context {
        let metrics: any TextMetrics
        let capabilities: PrintCapabilities
        private(set) var lines: [ReceiptLine] = []
        private(set) var degradations: [PrintDegradation] = []

        init(metrics: any TextMetrics, capabilities: PrintCapabilities) {
            self.metrics = metrics
            self.capabilities = capabilities
        }

        var lineWidth: Int { metrics.lineWidth }

        var spaceWidth: Int {
            max(1, metrics.cells(for: " ") * (metrics.cellWidth(of: .primary) ?? 1))
        }

        // MARK: Lowering

        mutating func blocks(_ elements: [PrintElement]) -> [ReceiptBlock] {
            var blocks: [ReceiptBlock] = []
            for element in elements {
                switch element {
                case .text(let runs, let alignment):
                    blocks.append(.text(runs, alignment: alignment))
                case .spacer:
                    continue
                case .divider(let character, let style):
                    blocks.append(.divider(character, style: style))
                case .feed(let lines):
                    blocks.append(.spacing(lines: lines))
                case .image(let image, let alignment):
                    blocks.append(.image(image, alignment: alignment))
                case .qrCode(let code, let alignment):
                    blocks.append(.qrCode(code, alignment: alignment))
                case .barcode(let barcode, let alignment):
                    blocks.append(.barcode(barcode, alignment: alignment))
                case .verticalStack(let children, let spacing):
                    let spacingLines = lines(spacing)
                    var isFirst = true
                    for child in children {
                        let childBlocks = self.blocks([child])
                        guard !childBlocks.isEmpty else { continue }
                        if !isFirst, spacingLines > 0 { blocks.append(.spacing(lines: spacingLines)) }
                        blocks += childBlocks
                        isFirst = false
                    }
                case .horizontalStack(let children, _):
                    blocks += row(children)
                case .padding(let insets, let child):
                    if !insets.isZero { degrade(.paddingIgnored) }
                    blocks += self.blocks([child])
                }
            }
            return blocks
        }

        /// A row's text columns, split at the first spacer, followed by anything that is not text.
        private mutating func row(_ children: [PrintElement]) -> [ReceiptBlock] {
            var leading: [[StyledRun]] = []
            var trailing: [[StyledRun]] = []
            var hasPassedSpacer = false
            var extras: [PrintElement] = []

            func collect(_ elements: [PrintElement], into context: inout Context) {
                for element in elements {
                    switch element {
                    case .text(let runs, _):
                        if hasPassedSpacer { trailing.append(runs) } else { leading.append(runs) }
                    case .spacer:
                        hasPassedSpacer = true
                    case .verticalStack(let children, _), .horizontalStack(let children, _):
                        collect(children, into: &context)
                    case .padding(let insets, let child):
                        if !insets.isZero { context.degrade(.paddingIgnored) }
                        collect([child], into: &context)
                    case .divider, .feed, .image, .qrCode, .barcode:
                        extras.append(element)
                    }
                }
            }
            collect(children, into: &self)

            let row: [ReceiptBlock] = leading.isEmpty && trailing.isEmpty
                ? []
                : [.row(ReceiptRow(leading: leading, trailing: trailing))]
            return row + blocks(extras)
        }

        /// Spacing in whole lines: lines as given, a physical length rounded up to the lines it
        /// needs.
        private func lines(_ spacing: PrintLength) -> Int {
            if case .lines(let lines) = spacing { return max(0, lines) }
            let lineHeight = max(1, metrics.lineHeight)
            guard let dots = spacing.dots(dotsPerMillimeter: metrics.dotsPerMillimeter, lineHeight: lineHeight),
                  dots > 0 else { return 0 }
            return (dots + lineHeight - 1) / lineHeight
        }

        // MARK: Placement

        mutating func place(_ block: ReceiptBlock) {
            switch block {
            case .text(let runs, let alignment):
                placeText(glyphs(runs), alignment: alignment)
            case .row(let row):
                placeRow(row)
            case .divider(let character, let style):
                let glyph = glyph(character, style: printable(style))
                let count = glyph.width > 0 ? lineWidth / glyph.width : 0
                lines.append(count > 0 ? .text([Glyph](repeating: glyph, count: count).runs) : .blank)
            case .spacing(let count):
                lines += [ReceiptLine](repeating: .blank, count: max(0, count))
            case .image(let image, let alignment):
                guard capabilities.contains(.images) else { return degrade(.imageOmitted) }
                lines.append(.image(image.bitmap(width: min(image.width, lineWidth)), alignment: alignment))
            case .qrCode(let code, let alignment):
                guard capabilities.contains(.qrCodes) else { return degrade(.qrCodeOmitted) }
                lines.append(.qrCode(code, alignment: alignment))
            case .barcode(let barcode, let alignment):
                guard capabilities.contains(.barcodes) else { return degrade(.barcodeOmitted) }
                lines.append(.barcode(barcode, alignment: alignment))
            }
        }

        // MARK: Text

        private mutating func placeText(_ glyphs: [Glyph], alignment: PrintAlignment) {
            for line in glyphs.wrapped(toWidth: lineWidth) {
                let width = line.width
                let offset = switch alignment {
                case .leading: 0
                case .center: (lineWidth - width) / 2
                case .trailing: lineWidth - width
                }
                lines.append(compose([(offset, line)]))
            }
        }

        // MARK: Rows

        private mutating func placeRow(_ row: ReceiptRow) {
            var leading: [[Glyph]] = []
            for column in row.leading { leading.append(glyphs(column)) }
            var trailing: [[Glyph]] = []
            for column in row.trailing { trailing.append(glyphs(column)) }
            guard !leading.isEmpty || !trailing.isEmpty else { return }

            func groupWidth(_ columns: some Collection<[Glyph]>) -> Int {
                columns.isEmpty ? 0 : columns.reduce(0) { $0 + $1.width } + (columns.count - 1) * spaceWidth
            }

            let flexibleIsLeading = !leading.isEmpty
            let flexible = flexibleIsLeading ? leading[leading.count - 1] : trailing[0]
            let fixedLeading = flexibleIsLeading ? Array(leading.dropLast()) : []
            let fixedTrailing = flexibleIsLeading ? trailing : Array(trailing.dropFirst())

            var reserved = groupWidth(fixedLeading) + groupWidth(fixedTrailing)
            if !fixedLeading.isEmpty { reserved += spaceWidth }
            if !fixedTrailing.isEmpty { reserved += spaceWidth }
            let flexibleWidth = lineWidth - reserved

            guard flexibleWidth >= spaceWidth else {
                degrade(.rowOverflow)
                let space = glyph(" ", style: .plain)
                let columns: [[Glyph]] = (leading + trailing).filter { !$0.isEmpty }
                placeText(Array(columns.joined(separator: [space])), alignment: .leading)
                return
            }

            let flexibleLines = flexible.wrapped(toWidth: flexibleWidth)
            var segments: [(Int, [Glyph])] = []

            var x = 0
            for column in fixedLeading {
                segments.append((x, column))
                x += column.width + spaceWidth
            }
            let trailingStart = lineWidth - groupWidth(fixedTrailing)
            var tx = trailingStart
            for column in fixedTrailing {
                segments.append((tx, column))
                tx += column.width + spaceWidth
            }

            let flexibleRightEdge = fixedTrailing.isEmpty ? lineWidth : trailingStart - spaceWidth
            func flexibleOffset(_ line: [Glyph]) -> Int {
                flexibleIsLeading ? x : flexibleRightEdge - line.width
            }

            segments.append((flexibleOffset(flexibleLines[0]), flexibleLines[0]))
            lines.append(compose(segments))
            for line in flexibleLines.dropFirst() {
                lines.append(compose([(flexibleOffset(line), line)]))
            }
        }

        // MARK: Composition

        /// Builds one line from positioned glyphs, padding the gaps with plain spaces.
        private func compose(_ segments: [(Int, [Glyph])]) -> ReceiptLine {
            var glyphs: [Glyph] = []
            var cursor = 0
            let space = glyph(" ", style: .plain)
            for (offset, segment) in segments.sorted(by: { $0.0 < $1.0 }) where !segment.isEmpty {
                if offset > cursor {
                    let count = (offset - cursor) / spaceWidth
                    glyphs += [Glyph](repeating: space, count: count)
                    cursor += count * spaceWidth
                }
                glyphs += segment
                cursor += segment.width
            }
            return glyphs.isEmpty ? .blank : .text(glyphs.runs)
        }

        // MARK: Glyphs and styles

        private mutating func glyphs(_ runs: [StyledRun]) -> [Glyph] {
            runs.flatMap { run in
                let style = printable(run.style)
                return run.text.map { glyph($0, style: style) }
            }
        }

        private func glyph(_ character: Character, style: TextStyle) -> Glyph {
            let cell = metrics.cellWidth(of: style.font) ?? metrics.cellWidth(of: .primary) ?? 1
            let cells = character == "\n" || character == "\r\n" ? 0 : metrics.cells(for: character)
            return Glyph(character: character, style: style, width: cells * cell * style.size.width)
        }

        /// The style as this printer can print it, reporting what had to go.
        private mutating func printable(_ style: TextStyle) -> TextStyle {
            var style = style
            if style.isUnderlined, !capabilities.contains(.underline) {
                style.isUnderlined = false
                degrade(.styleUnavailable(.underline))
            }
            if style.isInverted, !capabilities.contains(.inverted) {
                style.isInverted = false
                degrade(.styleUnavailable(.inverted))
            }
            if style.font == .secondary,
               !capabilities.contains(.secondaryFont) || metrics.cellWidth(of: .secondary) == nil {
                style.font = .primary
                degrade(.styleUnavailable(.secondaryFont))
            }
            let maximum = max(1, metrics.maximumMagnification)
            if style.size.width > maximum || style.size.height > maximum {
                let printed = TextSize(width: min(style.size.width, maximum), height: min(style.size.height, maximum))
                degrade(.magnificationReduced(requested: style.size, printed: printed))
                style.size = printed
            }
            return style
        }

        mutating func degrade(_ degradation: PrintDegradation) {
            if !degradations.contains(degradation) {
                degradations.append(degradation)
            }
        }
    }
}
