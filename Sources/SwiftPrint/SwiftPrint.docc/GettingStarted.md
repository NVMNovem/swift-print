# Getting Started

Declare a receipt, preview it as text and render it for a printer.

## Overview

Content is a type that conforms to ``PrintContent``. Its ``PrintContent/body`` is built with
``PrintBuilder``, so it takes the same statements as a SwiftUI view: content, plain strings, `if`,
`switch` and `for`.

### Declare a receipt

```swift
import SwiftPrint

struct OrderLine {
    let quantity: Int
    let name: String
    let price: String
}

struct OrderReceipt: PrintContent {
    let number: Int
    let lines: [OrderLine]
    let total: String
    let note: String?

    var body: some PrintContent {
        VStack(spacing: .lines(1)) {
            Text("#\(number)").bold().size(.double).alignment(.center)
            Divider()
            ForEach(lines) { line in
                HStack {
                    Text("\(line.quantity)×")
                    Text(line.name)
                    Spacer()
                    Text(line.price)
                }
            }
            Divider()
            HStack {
                Text("Total").bold()
                Spacer()
                Text(total).bold()
            }
            if let note {
                Text(note)
            }
            QRCode("https://example.com/orders/\(number)").alignment(.center)
        }
    }
}
```

- ``VStack`` places content one piece under the other. On a receipt its spacing is whole lines;
  give it `.lines(_:)`.
- ``HStack`` places content side by side; on a receipt, one row of text columns. Columns before the
  ``Spacer`` hold to the left edge, columns after it to the right. The column just before the
  spacer wraps; the others keep their width, so a long product name wraps while its price stays on
  the first line.
- ``ForEach`` repeats content for every element of a sequence.
- Modifiers such as `bold()`, `size(_:)`, `font(_:)` and `alignment(_:)` apply to everything inside
  that has not chosen otherwise. Texts joined with `+` print on one line, each in its own style.

Content outside any layout is a receipt; wrapping it in ``ReceiptLayout`` says so explicitly.

### Preview it as text

`PlainTextReceiptDriver` renders a receipt as UTF-8 text, one character per cell, with pictures
and codes as placeholders, which suits previews, logs and tests:

```swift
let preview = Printer(driver: PlainTextReceiptDriver(), options: PrintOptions(paperWidth: .millimeters80))
let rendered = try preview.render(receipt)
print(String(decoding: rendered.bytes, as: UTF8.self))
```

``Printer/render(_:)-(PrintDocument)`` and ``Printer/layout(_:)`` do no I/O.

### Render it for a printer

Rendering needs a driver for the printer's protocol: `ESCPOSDriver` from `SwiftPrintESCPOS` for
receipt printers, `ZPLDriver` from `SwiftPrintZPL` for label printers.

```swift
import SwiftPrintESCPOS

let printer = Printer(driver: .escpos(profile: .epsonTM))
let rendered = try printer.render(receipt)
```

The rendered document lists its degradations — anything printed differently because the printer
cannot do it, such as a `€` it lacks or a QR code it cannot draw.

### Send it

SwiftPrint does no networking. Send `rendered.bytes` with the protocol library's network module,
such as `SwiftESCPOSNetwork`, or give the printer a `PrintTransport` and call
``Printer/print(_:)-(PrintDocument)``. Success means the printer accepted every byte. A thrown
`PrintError` carries a `delivery`: only `.notSent` makes trying again safe from printing twice.

``Printer`` does not queue, retry or remember, and two calls to one printer at once are yours to
prevent.
