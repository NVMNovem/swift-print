//
//  ReceiptLayout.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Places a ``ReceiptDocument`` on the paper of one printer.
///
/// A receipt is a grid of character cells, so this is a column layout, not a layout engine: text
/// wraps at spaces, a row keeps its fixed columns and wraps its flexible one, and alignment pads
/// with plain spaces. Everything is measured in the printer's dots through ``TextMetrics``, so a
/// double-width character or a character printed as three is accounted for. The same document and
/// metrics always produce the same lines.
public struct ReceiptLayout: Sendable {
    public let metrics: any TextMetrics
    public let capabilities: ReceiptCapabilities

    public init(metrics: any TextMetrics, capabilities: ReceiptCapabilities) {
        self.metrics = metrics
        self.capabilities = capabilities
    }

    public func layout(_ document: ReceiptDocument) -> LaidOutReceipt {
        var context = Context(metrics: metrics, capabilities: capabilities)
        for block in document.blocks {
            context.place(block)
        }
        return LaidOutReceipt(lines: context.lines, degradations: context.degradations)
    }
}

// MARK: - Context

extension ReceiptLayout {
    /// A character with the style and width it will print at.
    struct Glyph: Hashable {
        let character: Character
        let style: TextStyle
        let width: Int
    }

    struct Context {
        let metrics: any TextMetrics
        let capabilities: ReceiptCapabilities
        private(set) var lines: [ReceiptLine] = []
        private(set) var degradations: [ReceiptDegradation] = []

        init(metrics: any TextMetrics, capabilities: ReceiptCapabilities) {
            self.metrics = metrics
            self.capabilities = capabilities
        }

        var lineWidth: Int { metrics.lineWidth }

        var spaceWidth: Int {
            max(1, metrics.cells(for: " ") * (metrics.cellWidth(of: .primary) ?? 1))
        }

        mutating func place(_ block: ReceiptBlock) {
            switch block {
            case .text(let runs, let alignment):
                placeText(glyphs(runs), alignment: alignment)
            case .row(let row):
                placeRow(row)
            case .divider(let character, let style):
                let glyph = glyph(character, style: printable(style))
                let count = glyph.width > 0 ? lineWidth / glyph.width : 0
                lines.append(count > 0 ? .text(runs([Glyph](repeating: glyph, count: count))) : .blank)
            case .spacing(let count):
                lines += [ReceiptLine](repeating: .blank, count: max(0, count))
            case .image(let image, let alignment):
                guard capabilities.contains(.images) else { return degrade(.imageOmitted) }
                lines.append(.image(image.bitmap(width: min(image.width, lineWidth)), alignment: alignment))
            case .qrCode(let code, let alignment):
                guard capabilities.contains(.qrCodes) else { return degrade(.qrCodeOmitted) }
                lines.append(.qrCode(code, alignment: alignment))
            }
        }

        // MARK: Text

        private mutating func placeText(_ glyphs: [Glyph], alignment: ReceiptAlignment) {
            for line in wrap(glyphs, width: lineWidth) {
                let width = line.reduce(0) { $0 + $1.width }
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

            func width(_ glyphs: [Glyph]) -> Int { glyphs.reduce(0) { $0 + $1.width } }
            func groupWidth(_ columns: some Collection<[Glyph]>) -> Int {
                columns.isEmpty ? 0 : columns.reduce(0) { $0 + width($1) } + (columns.count - 1) * spaceWidth
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

            let flexibleLines = wrap(flexible, width: flexibleWidth)
            var segments: [(Int, [Glyph])] = []

            var x = 0
            for column in fixedLeading {
                segments.append((x, column))
                x += width(column) + spaceWidth
            }
            let trailingStart = lineWidth - groupWidth(fixedTrailing)
            var tx = trailingStart
            for column in fixedTrailing {
                segments.append((tx, column))
                tx += width(column) + spaceWidth
            }

            let flexibleRightEdge = fixedTrailing.isEmpty ? lineWidth : trailingStart - spaceWidth
            func flexibleOffset(_ line: [Glyph]) -> Int {
                flexibleIsLeading ? x : flexibleRightEdge - width(line)
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
                cursor += segment.reduce(0) { $0 + $1.width }
            }
            return glyphs.isEmpty ? .blank : .text(runs(glyphs))
        }

        private func runs(_ glyphs: [Glyph]) -> [StyledRun] {
            var runs: [StyledRun] = []
            for glyph in glyphs {
                if let last = runs.last, last.style == glyph.style {
                    runs[runs.count - 1].text.append(glyph.character)
                } else {
                    runs.append(StyledRun(String(glyph.character), style: glyph.style))
                }
            }
            return runs
        }

        // MARK: Wrapping

        /// Greedy wrapping at spaces. A word wider than the line is broken between characters;
        /// spaces at a break are dropped; a line break in the text always starts a new line.
        private func wrap(_ glyphs: [Glyph], width: Int) -> [[Glyph]] {
            var wrapper = Wrapper(width: width)
            for glyph in glyphs {
                switch glyph.character {
                case "\n", "\r\n":
                    wrapper.breakLine()
                case " ":
                    wrapper.addSpace(glyph)
                default:
                    wrapper.addLetter(glyph)
                }
            }
            return wrapper.finish()
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
                let printed = ReceiptTextSize(width: min(style.size.width, maximum), height: min(style.size.height, maximum))
                degrade(.magnificationReduced(requested: style.size, printed: printed))
                style.size = printed
            }
            return style
        }

        private mutating func degrade(_ degradation: ReceiptDegradation) {
            if !degradations.contains(degradation) {
                degradations.append(degradation)
            }
        }
    }

    /// The state of a greedy wrap.
    struct Wrapper {
        let width: Int
        private var lines: [[Glyph]] = []
        private var line: [Glyph] = []
        private var lineWidth = 0
        private var word: [Glyph] = []
        private var wordWidth = 0
        private var spaces: [Glyph] = []
        private var spacesWidth = 0

        init(width: Int) {
            self.width = max(1, width)
        }

        mutating func addLetter(_ glyph: Glyph) {
            word.append(glyph)
            wordWidth += glyph.width
        }

        mutating func addSpace(_ glyph: Glyph) {
            placeWord()
            spaces.append(glyph)
            spacesWidth += glyph.width
        }

        mutating func breakLine() {
            placeWord()
            flush()
            spaces = []
            spacesWidth = 0
        }

        mutating func finish() -> [[Glyph]] {
            placeWord()
            if !line.isEmpty || lines.isEmpty {
                flush()
            }
            return lines
        }

        private mutating func placeWord() {
            guard !word.isEmpty else { return }
            if !line.isEmpty, lineWidth + spacesWidth + wordWidth > width {
                flush()
            }
            if !line.isEmpty {
                line += spaces
                lineWidth += spacesWidth
            }
            for glyph in word {
                if !line.isEmpty, lineWidth + glyph.width > width {
                    flush()
                }
                line.append(glyph)
                lineWidth += glyph.width
            }
            word = []
            wordWidth = 0
            spaces = []
            spacesWidth = 0
        }

        private mutating func flush() {
            lines.append(line)
            line = []
            lineWidth = 0
        }
    }
}
