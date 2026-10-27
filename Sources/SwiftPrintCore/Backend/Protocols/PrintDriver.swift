//
//  PrintDriver.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Speaks one printer protocol: says what the printer can do, measures and renders. No I/O.
///
/// A driver renders the layouts its protocol can print by also conforming to ``ReceiptDriver``,
/// ``LabelDriver`` or both. It is a value: it holds no connection and no queue, and
/// ``PrintOptions`` are handed to it for each call. Sending the bytes is a ``PrintTransport``'s job.
public protocol PrintDriver: Sendable {
    /// What the printer can do with these options, such as at this paper width.
    func capabilities(for options: PrintOptions) -> PrintCapabilities
}

/// A driver that prints receipts: text in lines of character cells, as long as the content needs.
public protocol ReceiptDriver: PrintDriver {
    /// How wide text prints with these options. Throws when the printer cannot take them, such as a
    /// paper width it lacks.
    func metrics(for options: PrintOptions) throws(PrintError) -> any TextMetrics
    /// The bytes for a laid-out receipt, with anything printed differently.
    func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(PrintError) -> RenderedDocument
}

/// A driver that prints labels: content at positions on a label of a fixed size.
public protocol LabelDriver: PrintDriver {
    /// How the printer measures a label with these options.
    func labelMetrics(for options: PrintOptions) throws(PrintError) -> any LabelMetrics
    /// The bytes for a laid-out label. Throws when the printer cannot print it as laid out; a label
    /// is never printed differently from how it was written.
    func render(_ label: LaidOutLabel, options: PrintOptions) throws(PrintError) -> RenderedDocument
}
