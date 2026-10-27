//
//  PrintTransport.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// Carries rendered bytes to a printer.
///
/// The framework ships no transport: how bytes reach a printer — the protocol libraries' network
/// modules, a serial port, a print server — is the application's choice. A transport adapts that
/// choice to one API, so printing can go through a printer value and be tested with a double.
public protocol PrintTransport: Sendable {
    /// Sends the bytes to the printer.
    ///
    /// A thrown error's ``PrintError/delivery`` must say exactly how much reached the printer, so a
    /// caller knows whether trying again could print twice.
    func send(_ bytes: [UInt8]) async throws(PrintError) -> PrintOutcome

    /// Asks the printer for its status, or throws ``PrintError/Reason/unsupported(_:)`` when the
    /// transport or printer cannot answer.
    func status() async throws(PrintError) -> PrinterStatus
}

extension PrintTransport {
    public func status() async throws(PrintError) -> PrinterStatus {
        throw PrintError(delivery: .notSent, reason: .unsupported("status, over this transport"))
    }
}
