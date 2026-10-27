# ``SwiftPrint``

Declare receipts and labels like SwiftUI views and render them for receipt and label printers.

## Overview

SwiftPrint turns content you declare in Swift into the bytes a printer understands. You describe
what is printed with ``PrintContent`` — text, stacks, dividers, images, QR codes and barcodes — and
hand it to a ``Printer``, which lays it out with the layout its format names and renders it
through a driver.

```swift
struct ProductLabel: PrintContent {
    let number: String

    var body: some PrintContent {
        LabelLayout(width: .millimeters(100), height: .millimeters(50)) {
            VStack(alignment: .leading) {
                Text("Product \(number)").size(.double)
                Spacer()
                Barcode(number)
            }
            .padding(.millimeters(1))
        }
    }
}
```

Content in a ``LabelLayout`` prints as a label of that size; any other content, or content in a
``ReceiptLayout``, as a receipt. The same components work in both, within what the printer can do.

Content is a function of its input: there is no state, no environment and no identity, so the same
content always prints the same bytes. On a receipt, what a printer cannot do is left off or printed
differently, and reported as a `PrintDegradation`; on a label it is refused with a `PrintError`.

This module re-exports `SwiftPrintCore`, which holds the document model, both layouts and the
driver and transport protocols. Drivers live in `SwiftPrintESCPOS` and `SwiftPrintZPL`.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:PrintingLabels>
- ``PrintContent``
- ``Printer``

### Layouts

- ``ReceiptLayout``
- ``LabelLayout``

### Text

- ``Text``
- ``Divider``
- ``Feed``

### Arranging content

- ``VStack``
- ``HStack``
- ``Spacer``
- ``ForEach``
- ``Group``

### Images and codes

- ``Image``
- ``QRCode``
- ``Barcode``

### Styling

- ``ModifiedContent``

### Building content

- ``PrintBuilder``
