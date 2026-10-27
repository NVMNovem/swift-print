# ``SwiftPrintCore``

The printer-independent receipt model, its layout and the driver protocol.

## Overview

`SwiftPrint` builds on this module and re-exports it; import it on its own to work with
documents and drivers without the declarative content.

A receipt passes through three stages:

1. A ``ReceiptDocument`` says what is on the receipt and how it should look, as
   ``ReceiptBlock``s. It never contains a cut, a drawer kick or a beep: those are chosen with
   ``PrintOptions``.
2. ``ReceiptLayout`` places the document on one printer's paper, measured through that printer's
   ``TextMetrics``, and degrades whatever its ``ReceiptCapabilities`` lack. The result is a
   ``LaidOutReceipt``.
3. A ``ReceiptDriver`` renders the laid-out receipt to a ``RenderedReceipt`` — the bytes for its
   protocol — and sends them over a ``ReceiptConnection``.

Each stage is deterministic: the same document, metrics and options always produce the same
lines and bytes. Everything printed differently from how it was written is reported as a
``ReceiptDegradation``.

## Topics

### Documents

- ``ReceiptDocument``
- ``ReceiptBlock``
- ``ReceiptRow``
- ``StyledRun``
- ``TextStyle``
- ``ReceiptTextSize``
- ``ReceiptFont``
- ``ReceiptAlignment``
- ``ReceiptImage``
- ``ReceiptQRCode``

### Layout

- ``ReceiptLayout``
- ``LaidOutReceipt``
- ``ReceiptLine``
- ``ReceiptBitmap``
- ``TextMetrics``
- ``ReceiptCapabilities``
- ``ReceiptDegradation``

### Drivers

- ``ReceiptDriver``
- ``PlainTextReceiptDriver``
- ``RenderedReceipt``

### Printing

- ``ReceiptConnection``
- ``PrintOptions``
- ``ReceiptPaperWidth``
- ``ReceiptCut``
- ``PrintOutcome``
- ``ReceiptPrintError``
- ``ReceiptPrinterStatus``
