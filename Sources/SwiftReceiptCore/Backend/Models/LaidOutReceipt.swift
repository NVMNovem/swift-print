//
//  LaidOutReceipt.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A receipt placed at one paper width for one driver: every line, and everything that had to be
/// printed differently from how it was written.
public struct LaidOutReceipt: Sendable, Hashable {
    /// The printed lines, top to bottom.
    public var lines: [ReceiptLine]
    /// Everything printed differently from how it was written.
    public var degradations: [ReceiptDegradation]

    public init(lines: [ReceiptLine], degradations: [ReceiptDegradation] = []) {
        self.lines = lines
        self.degradations = degradations
    }

    /// The receipt as plain text, for previews, logs and tests.
    public var plainText: String {
        lines.map { line in
            switch line {
            case .text(let runs): runs.map(\.text).joined()
            case .blank: ""
            case .image(let bitmap, _): "[image \(bitmap.width)×\(bitmap.height)]"
            case .qrCode(let code, _): "[QR \(code.payload)]"
            }
        }
        .joined(separator: "\n")
    }
}
