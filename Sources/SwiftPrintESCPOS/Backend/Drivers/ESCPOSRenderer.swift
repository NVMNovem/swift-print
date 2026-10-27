//
//  ESCPOSRenderer.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Turns laid-out lines into ESC/POS commands.
///
/// Every receipt starts from `ESC @` and the chosen code page. A style command is sent only when a
/// run's style differs from the one in effect, alignment commands only around images and QR codes —
/// text is already positioned by layout — and the job ends with the configured feed and cut.
struct ESCPOSRenderer {
    let codePage: ESCPOSCodePage
    let defaultCodePage: ESCPOSCodePage
    let capabilities: PrintCapabilities
    let options: PrintOptions
    private(set) var degradations: [PrintDegradation] = []
    private var style = TextStyle.plain

    init(
        codePage: ESCPOSCodePage,
        defaultCodePage: ESCPOSCodePage,
        capabilities: PrintCapabilities,
        options: PrintOptions
    ) {
        self.codePage = codePage
        self.defaultCodePage = defaultCodePage
        self.capabilities = capabilities
        self.options = options
    }

    mutating func commands(for receipt: LaidOutReceipt) -> [ESCPOSCommand] {
        var commands: [ESCPOSCommand] = [.initialize]
        if codePage != defaultCodePage {
            commands.append(.codePage(codePage))
        }
        for line in receipt.lines {
            switch line {
            case .text(let runs):
                for run in runs {
                    commands += switchStyle(to: run.style)
                    commands.append(.text(run.text))
                    for replacement in codePage.encode(run.text).replacements {
                        degrade(.characterReplaced(replacement.character, with: replacement.replacement))
                    }
                }
                commands.append(.lineFeed)
            case .blank:
                commands.append(.lineFeed)
            case .image(let bitmap, let alignment):
                guard let image = ESCPOSRasterImage(
                    width: bitmap.width,
                    height: bitmap.height,
                    packedRows: bitmap.packedRows
                ) else { continue }
                commands += [.alignment(ESCPOSAlignment(alignment)), .rasterImage(image), .alignment(.leading)]
            case .qrCode(let code, let alignment):
                let qrCode = ESCPOSQRCode(
                    code.payload,
                    moduleSize: UInt8(clamping: min(max(code.moduleSize, 1), 16)),
                    errorCorrection: ESCPOSQRCode.ErrorCorrection(code.errorCorrection)
                )
                commands += [.alignment(ESCPOSAlignment(alignment)), .qrCode(qrCode), .lineFeed, .alignment(.leading)]
            case .barcode:
                // swift-escpos draws no barcodes, so the driver never reports the capability and
                // layout leaves them off, reported, before they reach here.
                continue
            }
        }
        commands += switchStyle(to: .plain)
        commands += finish()
        return commands
    }

    private mutating func switchStyle(to next: TextStyle) -> [ESCPOSCommand] {
        var commands: [ESCPOSCommand] = []
        if next.isBold != style.isBold { commands.append(.bold(next.isBold)) }
        if next.isUnderlined != style.isUnderlined { commands.append(.underline(next.isUnderlined ? .single : .none)) }
        if next.isInverted != style.isInverted { commands.append(.inverted(next.isInverted)) }
        if next.size != style.size {
            commands.append(.size(ESCPOSTextSize(
                width: UInt8(clamping: next.size.width),
                height: UInt8(clamping: next.size.height)
            )))
        }
        if next.font != style.font { commands.append(.font(next.font == .primary ? .a : .b)) }
        style = next
        return commands
    }

    private mutating func finish() -> [ESCPOSCommand] {
        let feedLines = UInt8(clamping: max(0, options.receipt.feedLines))
        guard let cut = options.receipt.cut else {
            return feedLines > 0 ? [.feed(lines: feedLines)] : []
        }
        switch cut {
        case .full where capabilities.contains(.fullCut):
            return [.cut(.full, feedLines: feedLines)]
        case .partial where capabilities.contains(.partialCut):
            return [.cut(.partial, feedLines: feedLines)]
        default:
            degrade(.cutUnavailable(cut))
            return feedLines > 0 ? [.feed(lines: feedLines)] : []
        }
    }

    private mutating func degrade(_ degradation: PrintDegradation) {
        if !degradations.contains(degradation) {
            degradations.append(degradation)
        }
    }
}

extension ESCPOSAlignment {
    init(_ alignment: PrintAlignment) {
        switch alignment {
        case .leading: self = .leading
        case .center: self = .center
        case .trailing: self = .trailing
        }
    }
}

extension ESCPOSQRCode.ErrorCorrection {
    init(_ errorCorrection: PrintQRCode.ErrorCorrection) {
        switch errorCorrection {
        case .low: self = .low
        case .medium: self = .medium
        case .quartile: self = .quartile
        case .high: self = .high
        }
    }
}
