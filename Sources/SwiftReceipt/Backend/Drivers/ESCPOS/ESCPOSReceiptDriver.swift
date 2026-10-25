//
//  ESCPOSReceiptDriver.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

#if ESCPOS
internal import SwiftESCPOS

/// Prints on ESC/POS printers through swift-escpos.
///
/// Text is printed in the best table the profile holds for Western European text — one with `€`
/// where there is one — and everything else is left to the profile's capabilities.
public struct ESCPOSReceiptDriver: ReceiptDriver {
    public let profile: ReceiptESCPOSProfile

    public init(profile: ReceiptESCPOSProfile) {
        self.profile = profile
    }

    public func capabilities(for options: PrintOptions) -> ReceiptCapabilities {
        let escpos = profile.escpos.capabilities
        var capabilities: ReceiptCapabilities = []
        if escpos.contains(.underline) { capabilities.insert(.underline) }
        if escpos.contains(.inverted) { capabilities.insert(.inverted) }
        if escpos.contains(.fontB) { capabilities.insert(.secondaryFont) }
        if escpos.contains(.rasterImages) { capabilities.insert(.images) }
        if escpos.contains(.qrCodes) { capabilities.insert(.qrCodes) }
        if escpos.contains(.fullCut) { capabilities.insert(.fullCut) }
        if escpos.contains(.partialCut) { capabilities.insert(.partialCut) }
        if escpos.contains(.realtimeStatus) { capabilities.insert(.status) }
        return capabilities
    }

    public func metrics(for options: PrintOptions) throws(ReceiptPrintError) -> any TextMetrics {
        let escpos = profile.escpos
        guard let paperWidth = ESCPOSPaperWidth(rawValue: options.paperWidth.rawValue),
              let lineWidth = escpos.printableDots[paperWidth] else {
            throw ReceiptPrintError(
                delivery: .notSent,
                reason: .unsupported("\(options.paperWidth.rawValue) mm paper on \(escpos.name)")
            )
        }
        return ESCPOSReceiptMetrics(profile: escpos, lineWidth: lineWidth, codePage: codePage)
    }

    public func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(ReceiptPrintError) -> RenderedReceipt {
        var renderer = ESCPOSReceiptRenderer(
            codePage: codePage,
            defaultCodePage: profile.escpos.defaultCodePage,
            capabilities: capabilities(for: options),
            options: options
        )
        let commands = renderer.commands(for: receipt)
        do {
            let bytes = try ESCPOSEncoder(profile: profile.escpos).encode(commands)
            return RenderedReceipt(bytes: bytes, degradations: renderer.degradations)
        } catch {
            throw ReceiptPrintError(delivery: .notSent, reason: .renderingFailed(String(describing: error)))
        }
    }

    public func send(
        _ receipt: RenderedReceipt,
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> PrintOutcome {
        do {
            let transmission = try await escposConnection(connection, options: options).send(receipt.bytes)
            return PrintOutcome(
                bytesSent: transmission.bytesSent,
                acknowledgement: .none,
                degradations: receipt.degradations,
                duration: transmission.duration
            )
        } catch {
            throw ReceiptPrintError(error)
        }
    }

    public func status(
        over connection: ReceiptConnection,
        options: PrintOptions
    ) async throws(ReceiptPrintError) -> ReceiptPrinterStatus {
        guard capabilities(for: options).contains(.status) else {
            throw ReceiptPrintError(delivery: .notSent, reason: .unsupported("status on \(profile.name)"))
        }
        do {
            return ReceiptPrinterStatus(try await escposConnection(connection, options: options).status())
        } catch {
            throw ReceiptPrintError(error)
        }
    }

    // MARK: - Helpers

    /// The first table the profile holds, in order of preference for Western European text.
    var codePage: ESCPOSCodePage {
        let escpos = profile.escpos
        let preferred: [ESCPOSCodePage] = [.pc858, .windows1252, .pc850, .pc437]
        return preferred.first(where: escpos.supports) ?? escpos.defaultCodePage
    }

    private func escposConnection(_ connection: ReceiptConnection, options: PrintOptions) -> ESCPOSConnection {
        switch connection {
        case .tcp(let host, let port):
            .tcp(
                host: host,
                port: port,
                timeouts: .init(
                    connect: options.connectTimeout,
                    write: options.writeTimeout,
                    statusRead: options.statusTimeout
                )
            )
        }
    }
}

extension ReceiptDriver where Self == ESCPOSReceiptDriver {
    /// An ESC/POS printer of this model.
    public static func escpos(profile: ReceiptESCPOSProfile) -> ESCPOSReceiptDriver {
        ESCPOSReceiptDriver(profile: profile)
    }
}
#endif
