//
//  ESCPOSDriver.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Prints receipts on ESC/POS printers, through swift-escpos's encoder.
///
/// Text is printed in the best table the profile holds for Western European text — one with `€`
/// where there is one — and everything else is left to the profile's capabilities. The driver only
/// produces bytes; send them with `SwiftESCPOSNetwork` or any other transport.
public struct ESCPOSDriver: ReceiptDriver {
    /// The printer model.
    public let profile: ESCPOSProfile

    /// A driver for this printer model.
    public init(profile: ESCPOSProfile) {
        self.profile = profile
    }

    public func capabilities(for options: PrintOptions) -> PrintCapabilities {
        let escpos = profile.capabilities
        var capabilities: PrintCapabilities = []
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

    public func metrics(for options: PrintOptions) throws(PrintError) -> any TextMetrics {
        let requested = options.receipt.paperWidth
        guard let paperWidth = ESCPOSPaperWidth(rawValue: requested.rawValue),
              let lineWidth = profile.printableDots[paperWidth] else {
            throw PrintError(delivery: .notSent, reason: .paperWidthUnsupported(requested))
        }
        return ESCPOSMetrics(profile: profile, lineWidth: lineWidth, codePage: codePage)
    }

    public func render(_ receipt: LaidOutReceipt, options: PrintOptions) throws(PrintError) -> RenderedDocument {
        var renderer = ESCPOSRenderer(
            codePage: codePage,
            defaultCodePage: profile.defaultCodePage,
            capabilities: capabilities(for: options),
            options: options
        )
        let commands = renderer.commands(for: receipt)
        do {
            let bytes = try ESCPOSEncoder(profile: profile).encode(commands)
            return RenderedDocument(bytes: bytes, degradations: renderer.degradations)
        } catch {
            throw PrintError(delivery: .notSent, reason: .renderingFailed(String(describing: error)))
        }
    }

    // MARK: - Helpers

    /// The first table the profile holds, in order of preference for Western European text.
    var codePage: ESCPOSCodePage {
        let preferred: [ESCPOSCodePage] = [.pc858, .windows1252, .pc850, .pc437]
        return preferred.first(where: profile.supports) ?? profile.defaultCodePage
    }
}

extension PrintDriver where Self == ESCPOSDriver {
    /// An ESC/POS printer of this model.
    public static func escpos(profile: ESCPOSProfile) -> ESCPOSDriver {
        ESCPOSDriver(profile: profile)
    }
}
