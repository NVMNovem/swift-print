# SwiftPrint

Declare receipts and labels like SwiftUI views, and turn them into the bytes a printer understands.

SwiftPrint lays content out for one printer — wrapping text, keeping prices in their column,
placing text, barcodes and QR codes on a label of a fixed size — and renders it through that
printer's protocol. It is a higher-level, optional framework on top of two protocol libraries,
which stay usable on their own:

- [swift-escpos](https://github.com/NVMNovem/swift-escpos) for ESC/POS receipt printers,
- [swift-zpl](https://github.com/NVMNovem/swift-zpl) for ZPL II label printers.

SwiftPrint produces bytes. How they reach the printer — the protocol libraries' network modules,
or anything else — is your application's choice.

## Requirements

- Swift 6.2 or later
- iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, or Linux

## Installation

Add the package with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/NVMNovem/swift-print.git", from: "1.0.0"),
],
```

Then add the products you need to your target. There are no traits to enable: each printer
protocol is its own library.

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SwiftPrint", package: "swift-print"),
        .product(name: "SwiftPrintESCPOS", package: "swift-print"), // ESC/POS receipt printers
        .product(name: "SwiftPrintZPL", package: "swift-print"),    // ZPL label printers
    ]
)
```

| Library | Import it for |
| --- | --- |
| `SwiftPrint` | The declarative content (`PrintContent`, `Text`, `VStack`, `ReceiptLayout`, `LabelLayout`, …) and `Printer`. Re-exports `SwiftPrintCore`. |
| `SwiftPrintCore` | The printer-independent document model, both layout engines and the driver and transport protocols. No dependencies. |
| `SwiftPrintESCPOS` | `ESCPOSDriver`, which renders receipts with swift-escpos. Re-exports `SwiftESCPOS`. |
| `SwiftPrintZPL` | `ZPLDriver`, which renders labels with swift-zpl. Re-exports `SwiftZPL`. |
| `SwiftPrintTesting` | `MockDriver` and `MockTransport`, for testing how your app prints without a printer. |

None of them depends on SwiftNIO. The protocol libraries' network modules, `SwiftESCPOSNetwork`
and `SwiftZPLNetwork`, are added to your target only if you send with them.

## Documents and content

Content is a type conforming to `PrintContent`, built like a SwiftUI view. The framework turns it
into a `PrintDocument`: the content as `PrintElement`s, and the layout it is placed with.

- **`ReceiptLayout`** — line after line at the paper's width, as long as the content needs. Content
  outside any layout is a receipt.
- **`LabelLayout(width:height:)`** — a label of a fixed size; content is measured and positioned
  within it, and refused when it does not fit.

The same components — `Text`, `VStack`, `HStack`, `Spacer`, `Divider`, `Image`, `QRCode`,
`Barcode`, `ForEach`, `Group` — work in both, within what the printer can do. A receipt prints
what a printer lacks differently, or leaves it off, and reports it; a label has no room to reflow,
so it refuses with a `PrintError` instead.

## A receipt

```swift
import SwiftPrint
import SwiftPrintESCPOS

struct OrderLine {
    let quantity: Int
    let name: String
    let price: String
}

struct OrderReceipt: PrintContent {
    let number: Int
    let lines: [OrderLine]
    let total: String

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
            QRCode("https://example.com/orders/\(number)").alignment(.center)
        }
    }
}

let receipt = OrderReceipt(
    number: 42,
    lines: [
        OrderLine(quantity: 2, name: "Fries", price: "€ 6,40"),
        OrderLine(quantity: 1, name: "Stoofvleessaus", price: "€ 2,10"),
    ],
    total: "€ 8,50"
)

let printer = Printer(
    driver: .escpos(profile: .epsonTM),
    options: PrintOptions(paperWidth: .millimeters80, cut: .partial)
)
let rendered = try printer.render(receipt)
// rendered.bytes: ESC/POS. rendered.degradations: anything printed differently.
```

In an `HStack`, columns before the `Spacer` hold to the left edge and columns after it to the
right. The column just before the spacer wraps, so a long product name wraps while its price stays
on the first line. On a receipt, `VStack` spacing is whole lines: give it `.lines(_:)`.

The ESC/POS profiles are swift-escpos's: `.epsonTM`, `.duraposDPT201` and `.generic`, or one you
build with `ESCPOSProfile(…)`.

## A label

```swift
import SwiftPrint
import SwiftPrintZPL

struct ProductLabel: PrintContent {
    let number: String
    let batch: String

    var body: some PrintContent {
        LabelLayout(width: .millimeters(100), height: .millimeters(50)) {
            VStack(alignment: .leading, spacing: .millimeters(0.5)) {
                Text("Product \(number)").size(.double)
                Text("Batch \(batch)")
                Spacer()
                Barcode(number)
            }
            .padding(.millimeters(1))
        }
    }
}

let printer = Printer(driver: .zpl(profile: .zebraZD420d203))
let rendered = try printer.render(ProductLabel(number: "1042", batch: "A-2026"))
// rendered.bytes: ^XA^CI28^PW800^LL400^FO8,8^A0N,60,60^FB784,1,0,L,0^FDProduct 1042^FS…^XZ
```

Lengths are `PrintLength`s: `.millimeters(_:)`, `.inches(_:)`, `.dots(_:)` — an integer literal is
dots — or `.lines(_:)` of plain text. Each is converted to dots once, with the printer's
resolution from its `ZPLProfile`, so the same label prints at the same size at 203 and 300 dpi.
On a label, `Spacer`s in a `VStack` share the height left over, and an `HStack` can hold any
content, such as a QR code next to its text.

`ZPLDriver` builds a `ZPLLabel` from `ZPLCommand`s and encodes it with `ZPLEncoder`, which checks
every command against the profile. A label wider than the printhead, content taller than the
label, a QR code on a profile without them or data a barcode cannot hold throws a `PrintError` —
nothing is left out silently. Media setup, such as `^MN` or `~SD`, goes in the driver's `setup`.

## Sending the bytes

`Printer.render(_:)` does no I/O. Send `rendered.bytes` however you reach the printer, for example
with the protocol libraries' network modules:

```swift
import SwiftESCPOSNetwork

let transmission = try await ESCPOSConnection.tcp(host: "192.168.1.50").send(rendered.bytes)
```

```swift
import SwiftZPLNetwork

let transmission = try await ZPLConnection.tcp(host: "192.168.1.60").send(rendered.bytes)
```

To print through `Printer` itself — and swap the printer for `MockTransport` in tests — adapt the
connection to a `PrintTransport` and pass it as the printer's `transport`:

```swift
import SwiftPrint
import SwiftZPLNetwork

struct ZPLTransport: PrintTransport {
    let connection: ZPLConnection

    func send(_ bytes: [UInt8]) async throws(PrintError) -> PrintOutcome {
        do {
            let transmission = try await connection.send(bytes)
            return PrintOutcome(bytesSent: transmission.bytesSent, duration: transmission.duration)
        } catch {
            let delivery: PrintError.Delivery = switch error.delivery {
            case .notSent: .notSent
            case .partiallySent(let confirmedBytes): .partiallySent(confirmedBytes: confirmedBytes)
            }
            throw PrintError(delivery: delivery, reason: .connectionFailed(String(describing: error.reason)))
        }
    }

    func status() async throws(PrintError) -> PrinterStatus {
        do {
            return PrinterStatus(try await connection.status())
        } catch {
            throw PrintError(delivery: .notSent, reason: .connectionFailed(String(describing: error.reason)))
        }
    }
}

let printer = Printer(
    driver: .zpl(profile: .zebraZD420d203),
    transport: ZPLTransport(connection: .tcp(host: "192.168.1.60"))
)
let outcome = try await printer.print(ProductLabel(number: "1042", batch: "A-2026"))
```

Success means the printer accepted every byte. On failure, `PrintError.delivery` says whether
printing again is safe: only `.notSent` rules out a duplicate. `PrinterStatus` has initialisers
from `ESCPOSPrinterStatus` and `ZPLHostStatus`.

## Preview without a printer

`PlainTextReceiptDriver` renders a receipt as text, and `LaidOutLabel.plainText` lists a label's
elements and frames:

```swift
let preview = Printer(driver: PlainTextReceiptDriver())
print(String(decoding: try preview.render(receipt).bytes, as: UTF8.self))
```

## Documentation

[`Docs/Architecture.md`](Docs/Architecture.md) explains how content, layout, rendering, encoding
and transport are separated. The libraries are documented with DocC catalogs in each target's
`.docc` folder; in Xcode, open `Package.swift` and choose **Product › Build Documentation**.

## Development

```bash
swift test
```

The tests need no printer: ESC/POS and ZPL output is checked byte for byte.
