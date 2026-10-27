# ``SwiftPrintZPL``

Render labels for ZPL II printers with swift-zpl.

## Overview

``ZPLDriver`` turns a laid-out label into one `ZPLLabel` of `ZPLCommand`s — `^PW` and `^LL` from the
label's size, then one field per element — and encodes it with swift-zpl's `ZPLEncoder`, which
checks every command against the printer's `ZPLProfile`. It is a `LabelDriver`: a `ReceiptLayout`
document is refused with `.layoutUnsupported(.receipt)`, and the receipt options in `PrintOptions` —
paper width, cut, feed — are never read.

```swift
import SwiftPrint
import SwiftPrintZPL

let printer = Printer(driver: .zpl(profile: .zebraZD420d203))
let rendered = try printer.render(
    LabelLayout(width: .millimeters(100), height: .millimeters(50)) {
        VStack(alignment: .leading) {
            Text("Product 1042").size(.double)
            Spacer()
            Barcode("1042")
        }
        .padding(.millimeters(1))
    }
)
```

This module re-exports `SwiftZPL`, so its profiles and commands are in scope.

### Measurement

Layout uses the profile's resolution to convert lengths to dots, and its printable width and
label length as limits. Text is set in the printer's scalable font, `^A0`, at the driver's
`textHeight` — 3.75 mm by default, 30 dots at 203 dpi — times the text's magnification. Each line
is a one-line field block (`^FB`) as wide as its frame, so the printer aligns it with its own glyph
widths. The font is proportional and the printer does not report its widths, so layout wraps by
an upper estimate of each character's width; these estimates have not yet been checked on a
printer.

A barcode is drawn without the printer's interpretation line; its text is laid out as its own,
centred line, so its size is known.

### Nothing is left out

A label wider than the printhead or the configured media, content taller than the label, a QR code or image on a profile
without them, an underlined or inverted style, a character the label's character set cannot hold
or data a barcode cannot encode throws a `PrintError`. Encoder refusals keep swift-zpl's
description in `PrintError.Reason.renderingFailed(_:)`.

### Setup and sending

The label stock loaded is the job's, in `LabelOptions.media`; layout refuses a label larger than
it. ZPL-only media setup — `^MN`, `^MT`, `^MM`, `^PR`, `~SD` — goes in the driver's `setup`,
copies in its `quantity`. The driver does no I/O: send the bytes with `SwiftZPLNetwork`, or adapt it to a
`PrintTransport` to print through `Printer`. `PrinterStatus.init(_:)` maps the `ZPLHostStatus` its
connection reads.

```swift
import SwiftZPLNetwork

try await ZPLConnection.tcp(host: "192.168.1.60").send(rendered.bytes)
```

## Topics

### Driver

- ``ZPLDriver``
