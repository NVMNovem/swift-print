//
//  ZPLRenderer.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// Turns a laid-out label into ZPL commands, one field per element, in dots.
///
/// The label's size is sent as `^PW` and `^LL`. A text element becomes a one-line field block as
/// wide as its frame, so the printer aligns it with its own glyph widths; a barcode is drawn
/// without the printer's interpretation line, whose text layout placed as its own element.
struct ZPLRenderer {
    /// The height of plain text, in dots.
    let textHeight: Int

    func commands(for label: LaidOutLabel) -> [ZPLCommand] {
        var commands: [ZPLCommand] = [.printWidth(.dots(label.width)), .labelLength(.dots(label.height))]
        for element in label.elements {
            let position = ZPLPosition(x: .dots(element.x), y: .dots(element.y))
            switch element.content {
            case .text(let run, let alignment):
                commands.append(.text(ZPLText(
                    run.text,
                    at: position,
                    font: .scalable,
                    height: .dots(textHeight * run.style.size.height),
                    width: .dots(textHeight * run.style.size.width),
                    block: ZPLText.Block(width: .dots(element.width), maximumLines: 1, alignment: ZPLTextAlignment(alignment))
                )))
            case .image(let bitmap):
                let image = ZPLRasterImage(width: bitmap.width, height: bitmap.height, packedRows: bitmap.packedRows)!
                commands.append(.graphic(ZPLGraphic(image, at: position)))
            case .qrCode(let code):
                commands.append(.qrCode(ZPLQRCode(
                    code.payload,
                    at: position,
                    magnification: code.moduleSize,
                    errorCorrection: ZPLQRCode.ErrorCorrection(code.errorCorrection)
                )))
            case .barcode(let barcode):
                commands.append(.barcode(ZPLBarcode(
                    ZPLBarcode.Symbology(barcode.symbology),
                    data: barcode.data,
                    at: position,
                    height: .dots(element.height),
                    moduleWidth: barcode.moduleWidth,
                    interpretation: .none
                )))
            case .rule:
                commands.append(.box(ZPLBox(
                    at: position,
                    width: .dots(element.width),
                    height: .dots(element.height),
                    thickness: .dots(min(element.width, element.height))
                )))
            }
        }
        return commands
    }
}

extension ZPLTextAlignment {
    init(_ alignment: PrintAlignment) {
        switch alignment {
        case .leading: self = .left
        case .center: self = .center
        case .trailing: self = .right
        }
    }
}

extension ZPLQRCode.ErrorCorrection {
    init(_ errorCorrection: PrintQRCode.ErrorCorrection) {
        switch errorCorrection {
        case .low: self = .low
        case .medium: self = .medium
        case .quartile: self = .quartile
        case .high: self = .high
        }
    }
}

extension ZPLBarcode.Symbology {
    init(_ symbology: PrintBarcode.Symbology) {
        switch symbology {
        case .code128: self = .code128
        case .code39: self = .code39(checkDigit: false)
        case .ean13: self = .ean13
        }
    }
}
