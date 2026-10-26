# Printing with ESC/POS

Print on ESC/POS receipt printers over the network through swift-escpos.

## Overview

The ESC/POS driver is behind the package's `ESCPOS` trait, so an application that does not print
on ESC/POS printers does not depend on swift-escpos. Enable it where you add the package:

```swift
.package(
    url: "https://github.com/NVMNovem/swift-receipt.git",
    branch: "main",
    traits: ["ESCPOS"]
)
```

Your code imports only `SwiftReceipt`; swift-escpos stays an implementation detail. The driver,
`ESCPOSReceiptDriver`, and its `ReceiptESCPOSProfile` exist only with the trait enabled.

### Choose a profile

A `ReceiptESCPOSProfile` names a printer model and decides what the driver may send: code pages,
fonts, magnification, images, QR codes, cuts and status.

- `.epsonTM` — Epson TM-series printers on 80 mm paper.
- `.duraposDPT201` — DURAPOS DPT201-URE-BK.
- `.genericESCPOS` — a conservative subset for an unknown printer.

A profile's `id` is stable and may be stored, then restored with
`ReceiptESCPOSProfile(id:)`.

### Print

```swift
import SwiftReceipt

let printer = ReceiptPrinter(
    connection: .tcp(host: "192.168.1.50"),
    driver: .escpos(profile: .epsonTM),
    options: PrintOptions(paperWidth: .millimeters80, cut: .partial)
)

let outcome = try await printer.print(receipt)
```

`.tcp(host:port:)` uses raw port 9100 unless you give another. The connect, write and status
timeouts come from `PrintOptions`.

Text is printed in the best code page the profile holds for Western European text, one with `€`
where there is one. A character the code page lacks is replaced and reported as
`ReceiptDegradation.characterReplaced(_:with:)` — on the generic profile, `€` prints as `EUR`.

A paper width the profile has no printable width for is refused with
`ReceiptPrintError.Reason.unsupported(_:)` before anything is sent.

### Ask for status

On a profile that reports status, ``ReceiptPrinter/status()`` answers whether the printer is
online, its cover is open or it is out of paper:

```swift
if printer.capabilities.contains(.status) {
    let status = try await printer.status()
    if status.isReady == false { /* show the problem */ }
}
```
