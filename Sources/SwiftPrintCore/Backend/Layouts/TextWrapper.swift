//
//  TextWrapper.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// A character with the style and width it will print at.
struct Glyph: Hashable {
    let character: Character
    let style: TextStyle
    let width: Int

    var isLineBreak: Bool {
        character == "\n" || character == "\r\n"
    }
}

extension [Glyph] {
    /// The printed width, in dots.
    var width: Int {
        reduce(0) { $0 + $1.width }
    }

    /// The glyphs merged into runs of one style.
    var runs: [StyledRun] {
        var runs: [StyledRun] = []
        for glyph in self {
            if let last = runs.last, last.style == glyph.style {
                runs[runs.count - 1].text.append(glyph.character)
            } else {
                runs.append(StyledRun(String(glyph.character), style: glyph.style))
            }
        }
        return runs
    }

    /// Greedy wrapping at spaces, shared by both layouts. A word wider than the line is broken
    /// between characters; spaces at a wrap are dropped, while spaces at the start of the text or
    /// after a line break are kept as indentation; a line break in the text always starts a new line.
    func wrapped(toWidth width: Int) -> [[Glyph]] {
        var wrapper = TextWrapper(width: width)
        for glyph in self {
            if glyph.isLineBreak {
                wrapper.breakLine()
            } else if glyph.character == " " {
                wrapper.addSpace(glyph)
            } else {
                wrapper.addLetter(glyph)
            }
        }
        return wrapper.finish()
    }
}

/// The state of a greedy wrap.
struct TextWrapper {
    let width: Int
    private var lines: [[Glyph]] = []
    private var line: [Glyph] = []
    private var lineWidth = 0
    private var word: [Glyph] = []
    private var wordWidth = 0
    private var spaces: [Glyph] = []
    private var spacesWidth = 0
    /// At the start of the text or just after a line break, where spaces are indentation.
    private var isAtParagraphStart = true

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
        isAtParagraphStart = true
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
        if !line.isEmpty || isAtParagraphStart {
            line += spaces
            lineWidth += spacesWidth
        }
        isAtParagraphStart = false
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
