# ``SwiftPrintESCPOS``

Render receipts for ESC/POS printers with swift-escpos.

## Overview

``ESCPOSDriver`` turns a laid-out receipt into `ESCPOSCommand`s and encodes them with swift-escpos's
`ESCPOSEncoder`, which checks every command against the printer's `ESCPOSProfile`. It is a
`ReceiptDriver`: a label document is refused.

```swift
import SwiftPrint
import SwiftPrintESCPOS

let printer = Printer(
    driver: .escpos(profile: .epsonTM),
    options: PrintOptions(paperWidth: .millimeters80, cut: .partial)
)
let rendered = try printer.render(receipt)
```

This module re-exports `SwiftESCPOS`, so its profiles — `.epsonTM`, `.duraposDPT201`, `.generic`
or your own — are in scope.

### What is printed differently

Text is printed in the best code page the profile holds for Western European text, one with `€`
where there is one. A character the code page lacks is replaced and reported as
`PrintDegradation.characterReplaced(_:with:)` — on the generic profile, `€` prints as `EUR`.
Styles, images, QR codes and cuts the profile lacks are left off and reported. swift-escpos draws
no barcodes, so a barcode is left off and reported as `PrintDegradation.barcodeOmitted`.

A paper width the profile has no printable width for is refused with
`PrintError.Reason.unsupported(_:)` before anything is rendered.

### Sending

The driver does no I/O. Send the bytes with `SwiftESCPOSNetwork`, or adapt it to a
`PrintTransport` to print through `Printer`. `PrinterStatus.init(_:)` maps the
`ESCPOSPrinterStatus` its connection reads.

```swift
import SwiftESCPOSNetwork

try await ESCPOSConnection.tcp(host: "192.168.1.50").send(rendered.bytes)
```

## Topics

### Driver

- ``ESCPOSDriver``
