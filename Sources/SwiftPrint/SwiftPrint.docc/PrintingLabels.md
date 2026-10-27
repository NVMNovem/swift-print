# Printing Labels

Lay content out on a label of a fixed size.

## Overview

A ``LabelLayout`` is the root layout of a label document: it gives content an explicit width and
height, the size the label was designed for. Unlike a receipt, which grows as
long as its content, a label is a bounded box: everything in it is measured and positioned, and
content that does not fit is refused rather than cut off.

```swift
import SwiftPrint
import SwiftPrintZPL

struct ProductLabel: PrintDocument {
    let number: String
    let batch: String

    var body: some PrintLayout {
        LabelLayout(width: .millimeters(100), height: .millimeters(50)) {
            VStack(alignment: .leading, spacing: .millimeters(0.5)) {
                Text("Product \(number)").size(.double)
                Text("Batch \(batch)")
                Spacer()
                HStack {
                    Barcode(number)
                    Spacer()
                    QRCode("https://example.com/p/\(number)", moduleSize: 4)
                }
            }
            .padding(.millimeters(1))
        }
    }
}

let printer = Printer(
    driver: .zpl(profile: .zebraZD420d203),
    options: PrintOptions(label: LabelOptions(media: LabelMedia(width: .millimeters(100), height: .millimeters(50))))
)
let rendered = try printer.render(ProductLabel(number: "1042", batch: "A-2026"))
```

### Document size and media

The layout's size is the document's: what the label was designed for. The label stock in the
printer is the job's, configured with `LabelOptions/media` — `nil` when you do not know it, and a
`nil` height for continuous media. SwiftPrint never asks the printer what is loaded. Before any
content is placed, layout checks the size against both:

- `.invalidDimension(_:_:)` when a dimension is zero, negative or not finite;
- `.exceedsPrinter(_:dots:maximum:)` when it is more than the printer's profile prints;
- `.exceedsMedia(_:dots:media:)` when it is more than the configured media.

Labels are never clipped, scaled or printed on a different size.

### Lengths

Sizes, spacing and padding are `PrintLength`s: `.millimeters(_:)`, `.inches(_:)`, `.dots(_:)` — an
integer literal is dots — or `.lines(_:)` of plain text. Layout converts each to the printer's dots
once, with the resolution of its profile, then works in whole dots. The same label therefore prints
at the same size at 203 and 300 dpi, and rounding never accumulates.

### Placement

The label's content is placed one piece under the other, as in a ``VStack``.

- A ``VStack`` gives the height it has left to its ``Spacer``s, shared equally.
- An ``HStack`` places any content side by side, one plain space apart, and gives width left over
  to its spacers. When its pieces are too wide, the one before the first spacer wraps.
- `alignment(_:)` and `VStack(alignment:)` place text, pictures and codes across the width they
  have. A line of text in one style is aligned by the printer itself.
- `padding(_:)` insets content from the edges of the space it has.
- ``Text`` wraps at the width it has. ``Divider`` draws a thin rule; ``Feed`` adds empty lines.
- ``Barcode`` and ``QRCode`` take the size their data and module size need. A barcode's text is
  centred under its bars.

### When content does not fit

A label cannot reflow, so the layout never prints content differently from how it was written.
It throws a `PrintError` instead:

- `.contentOverflow(_:)` when content is taller than the label, or a code or a row of columns is
  wider than its space;
- `.unsupported(_:)` when content needs something the printer lacks, such as QR codes, images or
  underlined text.

The driver's encoder may refuse too — a character the label's character set cannot hold, or data
a barcode cannot encode — with `.renderingFailed(_:)`.
