# ``SwiftReceipt``

Declare receipts like SwiftUI views and print them on thermal receipt printers.

## Overview

SwiftReceipt turns a receipt you declare in Swift into the bytes a printer understands. You
describe what is on the receipt with ``ReceiptContent`` — text, rows of columns, dividers, images
and QR codes — and hand it to a ``ReceiptPrinter``, which lays it out for the paper, renders it
through a driver and sends it.

```swift
struct OrderReceipt: ReceiptContent {
    let number: Int
    let total: String

    var body: some ReceiptContent {
        VStack(spacing: 1) {
            Text("#\(number)").bold().size(.double).alignment(.center)
            HStack { Text("Total"); Spacer(); Text(total) }
        }
    }
}
```

A receipt is a function of its input: there is no state, no environment and no identity, so the
same content always prints the same bytes. What a printer cannot do is not sent; it is left off or
printed differently, and reported as a `ReceiptDegradation`.

This module re-exports `SwiftReceiptCore`, which holds the printer-independent model, the layout
and the driver protocol.

## Topics

### Essentials

- <doc:GettingStarted>
- ``ReceiptContent``
- ``ReceiptPrinter``

### Text

- ``Text``
- ``Divider``
- ``Feed``

### Layout

- ``VStack``
- ``HStack``
- ``Spacer``
- ``ForEach``
- ``Group``

### Images and codes

- ``Image``
- ``QRCode``

### Styling

- ``ModifiedContent``

### Building content

- ``ReceiptBuilder``

### ESC/POS printers

- <doc:PrintingWithESCPOS>
