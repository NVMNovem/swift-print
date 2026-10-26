# ``SwiftReceiptTesting``

Test how your application prints, without a printer.

## Overview

``MockReceiptDriver`` renders receipts as plain text, records everything it was asked to send in
its ``MockReceiptDriver/journal``, and answers each send with the response you give it. That lets
you test the receipt you print and how your application handles every outcome — including a
failure halfway through sending.

```swift
import SwiftReceipt
import SwiftReceiptTesting
import Testing

@Test func retriesOnlyWhenNothingWasSent() async throws {
    let driver = MockReceiptDriver(responses: [
        .failure(ReceiptPrintError(delivery: .partiallySent(confirmedBytes: 12), reason: .disconnected(.writing))),
    ])
    let printer = ReceiptPrinter(connection: .tcp(host: "printer.local"), driver: driver)

    await #expect(throws: ReceiptPrintError.self) {
        try await printer.print(Text("Order #42"))
    }
    #expect(await driver.journal.sent.count == 1)
}
```

## Topics

### Mocking a printer

- ``MockReceiptDriver``
