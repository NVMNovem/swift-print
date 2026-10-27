# ``SwiftPrint``

Declare receipts and labels like SwiftUI views and render them for receipt and label printers.

## Overview

SwiftPrint turns documents you declare in Swift into the bytes a printer understands. A
``PrintDocument`` declares its root layout — a ``ReceiptLayout`` or a ``LabelLayout`` — and the
layout holds the content: text, stacks, dividers, images, QR codes and barcodes. A ``Printer``
lays the document out with that layout and renders it through a driver.

```swift
struct ProductLabel: PrintDocument {
    let number: String

    var body: some PrintLayout {
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

Every document has exactly one root layout, and the compiler enforces it: a body of plain content
is not a document, and a layout cannot be placed inside content. Nothing prints as a receipt by
default. The same components work in both layouts, within what the printer can do.

Content is a function of its input: there is no state, no environment and no identity, so the same
content always prints the same bytes. On a receipt, what a printer cannot do is left off or printed
differently, and reported as a `PrintDegradation`; on a label it is refused with a `PrintError`.

This module re-exports `SwiftPrintCore`, which holds the document model, both layouts and the
driver and transport protocols. Drivers live in `SwiftPrintESCPOS` and `SwiftPrintZPL`.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:PrintingLabels>
- ``PrintDocument``
- ``Printer``

### Layouts

- ``PrintLayout``
- ``ReceiptLayout``
- ``LabelLayout``

### Content

- ``PrintContent``

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
