# ``SwiftPrintCore``

The printer-independent document model, the receipt and label layouts, and the driver and
transport protocols.

## Overview

`SwiftPrint` builds on this module and re-exports it; import it on its own to work with documents,
layouts and drivers without the declarative content. It has no dependencies and does no I/O.

A document passes through three stages here:

1. A ``PrintDocument`` says what is printed — ``PrintElement``s, with every style and alignment
   resolved — and its ``PrintDocument/Format``: a receipt, or a label of a ``LabelSize``. It never
   contains a cut, a drawer kick or a beep: those are chosen with ``PrintOptions``.
2. A layout places it for one printer, measured through that printer's metrics:
   - ``ReceiptLayoutEngine`` lays a receipt out line by line at the paper's width through
     ``TextMetrics``, degrading what the printer's ``PrintCapabilities`` lack and reporting each
     ``PrintDegradation``. The result is a ``LaidOutReceipt``.
   - ``LabelLayoutEngine`` positions a label's elements in dots within its size through
     ``LabelMetrics``, and throws a ``PrintError`` for content that does not fit or that the
     printer cannot print. The result is a ``LaidOutLabel``.
3. A ``ReceiptDriver`` or ``LabelDriver`` renders the laid-out document to a ``RenderedDocument`` —
   the bytes for its protocol.

Each stage is deterministic: the same document, metrics and options always produce the same
output. Sending the bytes is left to the application, optionally behind a ``PrintTransport``.

## Topics

### Documents

- ``PrintDocument``
- ``PrintElement``
- ``LabelSize``
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
- ``ReceiptPaperWidth``
- ``ReceiptCut``
- ``PrintOutcome``
- ``PrintError``
- ``PrinterStatus``
