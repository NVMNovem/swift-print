# Architecture

SwiftPrint turns declared content into bytes for one printer. It does that in separate layers,
each knowing only the one below it, so a new printer protocol or output format is a new driver,
not a new document API.

```text
PrintDocument → ReceiptLayout | LabelLayout        SwiftPrint
    holding PrintContent (Text, VStack, …)
    ↓  resolving: styles and alignment onto the content
ResolvedDocument: format + [PrintElement]           SwiftPrintCore
    ↓  ReceiptLayoutEngine | LabelLayoutEngine
LaidOutReceipt | LaidOutLabel                       SwiftPrintCore
    ↓  ReceiptDriver | LabelDriver
ESCPOSCommand | ZPLLabel / ZPLCommand               SwiftPrintESCPOS | SwiftPrintZPL
    ↓  ESCPOSEncoder | ZPLEncoder
[UInt8]                                             swift-escpos | swift-zpl
    ↓  the application's choice, optionally behind a PrintTransport
printer                                             SwiftESCPOSNetwork | SwiftZPLNetwork | …
```

## Responsibilities

| Part | Responsibility |
| --- | --- |
| `PrintDocument` | Printable content, under one root layout. |
| `ReceiptLayout` | A variable-height receipt: content flowing at the paper's width. |
| `LabelLayout` | A fixed-size label: a bounded canvas. |
| `PrintOptions` | The job: receipt paper, cut and feed; label media. |
| Printer profile | Hardware capabilities and limits. |
| Protocol adapter | Translation into printer commands. |

Receipt dimensions are flexible because a receipt is as long as its content and as wide as the roll
it happens to print on; the same receipt prints on 58 mm and 80 mm paper. Label dimensions are
explicit because a label is designed for specific stock: its content is positioned within that
size and must fit it. Cutting and feeding are done to the printer after the content, so they are
job options, not layout. A profile describes what a printer model can do, never what a document
contains or what media is loaded.

## 1. Documents and declarative content

`SwiftPrint` holds `PrintDocument`, the two layouts, the content types and `PrintBuilder`. Every
document's `body` is a root layout, and this is enforced by the compiler: `PrintDocument.Body`
must be a `PrintLayout`, and a layout is not `PrintContent`, so it can be neither left out nor
nested — `PrintBuilder` rejects a layout inside content with an explanation. There is no implicit
receipt and no layout chosen by the printer.

Content is a description, never a command: there is no state, environment or identity, and the
same input always gives the same document. Modifiers — `bold()`, `size(_:)`, `alignment(_:)`,
`padding(_:)` — apply to everything inside that has not chosen otherwise.

Resolving a document through its layout gives a `ResolvedDocument`: the layout's `Format` and the
content as a `PrintElement` tree with every style and alignment resolved, so `SwiftPrintCore`
carries no inheritance rules.

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

Sizes are checked before content is placed. A receipt's printable width comes from
`ReceiptOptions.paperWidth` and the driver's profile; a width the profile lacks is
`.paperWidthUnsupported`. A label's declared size must be a size (`.invalidDimension`), within the
profile's limits (`.exceedsPrinter`) and within the media in `LabelOptions` when it is configured
(`.exceedsMedia`). The media is what the application says is loaded; SwiftPrint never claims to
detect it, and a printer's maximum is never mistaken for the media.

## 3. Protocol-specific rendering

A driver turns a laid-out document into its protocol's model. `ESCPOSDriver` produces
`ESCPOSCommand`s and `ZPLDriver` a `ZPLLabel` of `ZPLCommand`s. Drivers are values with no I/O;
they say what their printer can do (`PrintCapabilities`) and how it measures.

A driver conforms to `ReceiptDriver`, `LabelDriver` or both. `Printer` lays a document out with the
layout it declares and refuses, with `.layoutUnsupported`, a layout its driver does not print.
`PrintOptions` is grouped by layout and a driver reads only its group, so a label driver never
receives a receipt cut; options only one protocol has, such as ZPL media tracking, belong to that
protocol's driver.

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
