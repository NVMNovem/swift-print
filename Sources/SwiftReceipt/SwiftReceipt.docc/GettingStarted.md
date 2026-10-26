# Getting Started

Declare a receipt, preview it as text and print it.

## Overview

A receipt is a type that conforms to ``ReceiptContent``. Its ``ReceiptContent/body`` is built with
``ReceiptBuilder``, so it takes the same statements as a SwiftUI view: content, plain strings, `if`,
`switch` and `for`.

### Declare a receipt

```swift
import SwiftReceipt

struct OrderLine {
    let quantity: Int
    let name: String
    let price: String
}

struct OrderReceipt: ReceiptContent {
    let number: Int
    let lines: [OrderLine]
    let total: String
    let note: String?

    var body: some ReceiptContent {
        VStack(spacing: 1) {
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

- ``VStack`` places content line after line, with empty lines between pieces when you give it a
  spacing.
- ``HStack`` makes one row of text columns. Columns before the ``Spacer`` hold to the left edge,
  columns after it to the right. The column just before the spacer wraps; the others keep their
  width, so a long product name wraps while its price stays on the first line.
- ``ForEach`` repeats content for every element of a sequence.
- Modifiers such as `bold()`, `size(_:)`, `font(_:)` and `alignment(_:)` apply to everything inside
  that has not chosen otherwise. Texts joined with `+` print on one line, each in its own style.

### Preview it as text

`PlainTextReceiptDriver` renders a receipt as UTF-8 text, one character per cell, with images and
QR codes as placeholders. It never sends, so it suits previews, logs and tests:

```swift
let preview = ReceiptPrinter(
    connection: .tcp(host: "localhost"),
    driver: PlainTextReceiptDriver(),
    options: PrintOptions(paperWidth: .millimeters80)
)
let rendered = try preview.render(receipt)
print(String(decoding: rendered.bytes, as: UTF8.self))
```

``ReceiptPrinter/render(_:)-(ReceiptDocument)`` and ``ReceiptPrinter/layout(_:)`` do no I/O.

### Print it

Printing needs a driver for the printer's protocol. For ESC/POS printers, see
<doc:PrintingWithESCPOS>.

```swift
let outcome = try await printer.print(receipt)
```

Success means the printer accepted every byte. A thrown `ReceiptPrintError` carries a `delivery`:
only `.notSent` makes trying again safe from printing the receipt twice. Both the outcome and the
rendered receipt list the degradations — anything printed differently because the printer cannot
do it, such as a `€` it lacks or a QR code it cannot draw.

``ReceiptPrinter`` does not queue, retry or remember. Each call opens its own connection, and two
calls to one printer at once are yours to prevent.
