//
//  RenderedDocument.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A document as the bytes one driver produced for its printer, with everything printed
/// differently. Sending them is up to the application, or a ``PrintTransport``.
public struct RenderedDocument: Sendable, Hashable {
    /// What is sent to the printer.
    public var bytes: [UInt8]
    /// Everything printed differently from how it was written.
    public var degradations: [PrintDegradation]

    public init(bytes: [UInt8], degradations: [PrintDegradation] = []) {
        self.bytes = bytes
        self.degradations = degradations
    }
}
