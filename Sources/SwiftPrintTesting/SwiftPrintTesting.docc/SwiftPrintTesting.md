# ``SwiftPrintTesting``

Test how your application prints, without a printer.

## Overview

``MockDriver`` prints receipts and labels as plain text, so you can test what your application
prints. ``MockTransport`` records everything it was asked to send in its
``MockTransport/journal`` and answers each send with the response you give it, so you can test how
your application handles every outcome — including a failure halfway through sending.

```swift
import SwiftPrint
import SwiftPrintTesting
import Testing

@Test func retriesOnlyWhenNothingWasSent() async throws {
    let transport = MockTransport(responses: [
        .failure(PrintError(delivery: .partiallySent(confirmedBytes: 12), reason: .disconnected(.writing))),
    ])
    let printer = Printer(driver: MockDriver(), transport: transport)

    await #expect(throws: PrintError.self) {
        try await printer.print(ReceiptLayout { Text("Order #42") })
    }
    #expect(await transport.journal.sent.count == 1)
}
```

## Topics

### Mocking a printer

- ``MockDriver``
- ``MockTransport``
