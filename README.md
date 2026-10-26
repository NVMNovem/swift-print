# SwiftReceipt

Declare receipts like SwiftUI views and print them on thermal receipt printers.

SwiftReceipt lays a receipt out for the printer's paper — wrapping text, keeping prices in their
column, scaling and dithering images — renders it through a driver and sends it. What a printer
cannot do is left off or printed differently, and reported, instead of being sent as bytes it
would misread.

## Requirements

- Swift 6.2 or later
- iOS 17, macOS 14, tvOS 17, watchOS 10 or visionOS 1

## Installation

Add the package with Swift Package Manager. To print on ESC/POS printers, enable the `ESCPOS`
trait, which brings in [swift-escpos](https://github.com/NVMNovem/swift-escpos):

```swift
dependencies: [
    .package(
        url: "https://github.com/NVMNovem/swift-receipt.git",
        branch: "main",
        traits: ["ESCPOS"]
    ),
],
```

Then add the product to your target:

```swift
.product(name: "SwiftReceipt", package: "swift-receipt")
```

The package has three libraries:

| Library | Use |
| --- | --- |
| `SwiftReceipt` | The receipt DSL, `ReceiptPrinter` and, with the `ESCPOS` trait, the ESC/POS driver. Re-exports `SwiftReceiptCore`. |
| `SwiftReceiptCore` | The printer-independent document model, layout and `ReceiptDriver` protocol. |
| `SwiftReceiptTesting` | `MockReceiptDriver`, for testing how your app prints without a printer. |

## Usage

### Create a receipt

A receipt is a type that conforms to `ReceiptContent`, built like a SwiftUI view:

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
            QRCode("https://example.com/orders/\(number)").alignment(.center)
        }
    }
}
```

In an `HStack`, columns before the `Spacer` hold to the left edge and columns after it to the
right. The column just before the spacer wraps, so a long product name wraps while its price stays
on the first line.

### Print it via SwiftESCPOS

With the `ESCPOS` trait enabled, print over the network on an ESC/POS printer:

```swift
let printer = ReceiptPrinter(
    connection: .tcp(host: "192.168.1.50"),
    driver: .escpos(profile: .epsonTM),
    options: PrintOptions(paperWidth: .millimeters80, cut: .partial)
)

let receipt = OrderReceipt(
    number: 42,
    lines: [
        OrderLine(quantity: 2, name: "Fries", price: "€ 6,40"),
        OrderLine(quantity: 1, name: "Stoofvleessaus", price: "€ 2,10"),
    ],
    total: "€ 8,50"
)

do {
    let outcome = try await printer.print(receipt)
    for degradation in outcome.degradations {
        print("Printed differently:", degradation)
    }
} catch {
    // Only `.notSent` makes printing again safe from a duplicate receipt.
    if error.delivery == .notSent {
        // Offer to try again.
    }
}
```

`.tcp(host:port:)` uses raw port 9100 unless you pass another. The profiles are `.epsonTM`,
`.duraposDPT201` and `.genericESCPOS`; a profile's `id` can be stored and restored with
`ReceiptESCPOSProfile(id:)`.

Success means the printer accepted every byte. `ReceiptPrinter` does not queue or retry, and each
call opens its own connection.

### Preview without a printer

`PlainTextReceiptDriver` renders a receipt as text, which suits previews, logs and tests. It never
sends.

```swift
let preview = ReceiptPrinter(
    connection: .tcp(host: "localhost"),
    driver: PlainTextReceiptDriver()
)
let rendered = try preview.render(receipt)
print(String(decoding: rendered.bytes, as: UTF8.self))
```

## Documentation

The libraries are documented with DocC catalogs in
[`Sources/SwiftReceipt/SwiftReceipt.docc`](Sources/SwiftReceipt/SwiftReceipt.docc),
[`Sources/SwiftReceiptCore/SwiftReceiptCore.docc`](Sources/SwiftReceiptCore/SwiftReceiptCore.docc) and
[`Sources/SwiftReceiptTesting/SwiftReceiptTesting.docc`](Sources/SwiftReceiptTesting/SwiftReceiptTesting.docc).
In Xcode, open `Package.swift` and choose **Product › Build Documentation**.

## Development

Run the tests, including the ESC/POS driver's:

```bash
swift test --traits ESCPOS
```
