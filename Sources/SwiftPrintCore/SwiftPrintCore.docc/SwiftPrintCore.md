# ``SwiftPrintCore``

The printer-independent document model, the receipt and label layouts, and the driver and
transport protocols.

## Overview

`SwiftPrint` builds on this module and re-exports it; import it on its own to work with documents,
layouts and drivers without the declarative content. It has no dependencies and does no I/O.

A document passes through three stages here:

1. A ``ResolvedDocument`` says what is printed — ``PrintElement``s, with every style and
   alignment resolved — and its ``ResolvedDocument/Format``: the receipt or label layout the
   document declared. It never contains a cut, a feed or a beep: those are the job's, chosen with
   ``PrintOptions``.
2. A layout places it for one printer, measured through that printer's metrics:
   - ``ReceiptLayoutEngine`` lays a receipt out line by line at the paper's width through
     ``TextMetrics``, degrading what the printer's ``PrintCapabilities`` lack and reporting each
     ``PrintDegradation``. The result is a ``LaidOutReceipt``.
   - ``LabelLayoutEngine`` checks a label's size against the printer and the configured
     ``LabelMedia``, positions its elements in dots through ``LabelMetrics``, and throws a
     ``PrintError`` for a size or content that does not fit, or that the printer cannot print. The
     result is a ``LaidOutLabel``.
3. A ``ReceiptDriver`` or ``LabelDriver`` renders the laid-out document to a ``RenderedDocument`` —
   the bytes for its protocol.

Each stage is deterministic: the same document, metrics and options always produce the same
output. Sending the bytes is left to the application, optionally behind a ``PrintTransport``.

## Topics

### Documents

- ``ResolvedDocument``
- ``PrintLayoutKind``
- ``PrintElement``
- ``LabelSize``
- ``PrintDimension``
- ``StyledRun``
- ``TextStyle``
- ``TextSize``
- ``PrintFont``
- ``PrintAlignment``
- ``PrintImage``
- ``PrintQRCode``
- ``PrintBarcode``

### Measurement

- ``PrintLength``
- ``PrintInsets``
- ``TextMetrics``
- ``LabelMetrics``
- ``PrintCapabilities``

### Receipt layout

- ``ReceiptLayoutEngine``
- ``ReceiptBlock``
- ``ReceiptRow``
- ``LaidOutReceipt``
- ``ReceiptLine``
- ``PrintBitmap``
- ``PrintDegradation``

### Label layout

- ``LabelLayoutEngine``
- ``LaidOutLabel``
- ``LabelElement``
- ``LaidOutDocument``

### Drivers

- ``PrintDriver``
- ``ReceiptDriver``
- ``LabelDriver``
- ``PlainTextReceiptDriver``
- ``RenderedDocument``

### Printing

- ``PrintTransport``
- ``PrintOptions``
- ``ReceiptOptions``
- ``LabelOptions``
- ``LabelMedia``
- ``ReceiptPaperWidth``
- ``ReceiptCut``
- ``PrintOutcome``
- ``PrintError``
- ``PrinterStatus``
