# Architecture

SwiftPrint turns declared content into bytes for one printer. It does that in separate layers,
each knowing only the one below it, so a new printer protocol or output format is a new driver,
not a new document API.

```text
PrintContent (Text, VStack, LabelLayout, …)        SwiftPrint
    ↓  lowering: styles and alignment resolved
PrintDocument: format + [PrintElement]              SwiftPrintCore
    ↓  ReceiptLayoutEngine | LabelLayoutEngine
LaidOutReceipt | LaidOutLabel                       SwiftPrintCore
    ↓  ReceiptDriver | LabelDriver
ESCPOSCommand | ZPLLabel / ZPLCommand               SwiftPrintESCPOS | SwiftPrintZPL
    ↓  ESCPOSEncoder | ZPLEncoder
[UInt8]                                             swift-escpos | swift-zpl
    ↓  the application's choice, optionally behind a PrintTransport
printer                                             SwiftESCPOSNetwork | SwiftZPLNetwork | …
```

## 1. Declarative content

`SwiftPrint` holds the content types and `PrintBuilder`. Content is a description, never a
command: there is no state, environment or identity, and the same input always gives the same
document. Modifiers — `bold()`, `size(_:)`, `alignment(_:)`, `padding(_:)` — apply to everything
inside that has not chosen otherwise.

Building a `PrintDocument` from content resolves every style and alignment onto the text, pictures
and codes, so the `PrintElement` tree in `SwiftPrintCore` carries no inheritance rules. The
outermost `ReceiptLayout` or `LabelLayout` decides the document's `Format`; content without one is
a receipt.

## 2. Layout: measurement and positioning

`SwiftPrintCore` has two layout engines, because receipts and labels are placed differently:

- **`ReceiptLayoutEngine`** works on a grid of character cells at a fixed width and grows as long
  as the content needs. Elements are lowered to `ReceiptBlock`s — a vertical stack to its blocks
  with blank lines between them, a horizontal stack to one `ReceiptRow` — and placed as
  `ReceiptLine`s padded with plain spaces. What the printer lacks is degraded and reported as a
  `PrintDegradation`.
- **`LabelLayoutEngine`** works in a bounded box of dots. Every element is measured and given a
  frame; vertical stacks share leftover height among their spacers, horizontal stacks share
  leftover width and wrap their flexible column. Content that does not fit, or that the printer
  cannot print, throws a `PrintError`: a label cannot reflow, and a label printed differently is a
  wrong label.

Both measure through a driver's metrics — `TextMetrics` for receipts, `LabelMetrics` for labels —
and share the text wrapping, the styles, image dithering and the size calculations of QR codes and
barcodes. A label is never laid out as an infinitely long receipt.

Physical lengths (`PrintLength`) are converted to dots once each, with the printer's resolution,
and layout then works in whole dots, so rounding never accumulates.

## 3. Protocol-specific rendering

A driver turns a laid-out document into its protocol's model. `ESCPOSDriver` produces
`ESCPOSCommand`s and `ZPLDriver` a `ZPLLabel` of `ZPLCommand`s. Drivers are values with no I/O;
they say what their printer can do (`PrintCapabilities`) and how it measures.

A driver conforms to `ReceiptDriver`, `LabelDriver` or both. `Printer` picks the layout from the
document's format and refuses a format its driver does not print.

## 4. Protocol encoding

Encoding stays in the protocol libraries: `ESCPOSEncoder` and `ZPLEncoder` check every command
against the printer's profile and produce the bytes. SwiftPrint duplicates none of it, and the
libraries remain usable without SwiftPrint.

## 5. Transport

SwiftPrint ships no transport and depends on no networking. `Printer.render(_:)` returns the bytes;
the application sends them with `SwiftESCPOSNetwork`, `SwiftZPLNetwork` or anything else. A
`PrintTransport` adapts that choice so printing can go through `Printer.print(_:)`, with
`PrintError.delivery` saying whether a retry could print twice, and so tests can use
`MockTransport`.

## Adding a protocol

A new protocol needs a target that depends on `SwiftPrintCore` and its encoding library, and a
driver conforming to `ReceiptDriver` or `LabelDriver`. The content, the document and both layouts
are unchanged.
