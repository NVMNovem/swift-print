//
//  ZPLDriver.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// Prints labels on ZPL II printers, through swift-zpl's label model and encoder.
///
/// Layout measures with the profile's resolution and limits; the laid-out label becomes one
/// ``ZPLLabel`` of ``ZPLCommand``s, and ``ZPLEncoder`` checks every command against the profile
/// before it becomes bytes. Text is set in the printer's scalable font. Anything the profile
/// cannot print, or data a code cannot hold, fails rendering with a ``PrintError``; nothing is left
/// out. The driver only produces bytes; send them with `SwiftZPLNetwork` or any other transport.
public struct ZPLDriver: LabelDriver {
    /// The printer model.
    public let profile: ZPLProfile
    /// The height of a line of plain text; magnified text is a multiple of it.
    public let textHeight: PrintLength
    /// Commands placed at the top of every label, such as ``ZPLCommand/mediaTracking(_:)`` or
    /// ``ZPLCommand/darkness(_:)``. Size, `^PW` and `^LL`, comes from the document.
    public let setup: [ZPLCommand]
    /// Copies of every label, `^PQ`.
    public let quantity: Int
    /// The `^CI` set for field data; `nil` uses the profile's default.
    public let characterEncoding: ZPLCharacterEncoding?

    /// A driver for this printer model.
    public init(
        profile: ZPLProfile,
        textHeight: PrintLength = .millimeters(3.75),
        setup: [ZPLCommand] = [],
        quantity: Int = 1,
        characterEncoding: ZPLCharacterEncoding? = nil
    ) {
        self.profile = profile
        self.textHeight = textHeight
        self.setup = setup
        self.quantity = quantity
        self.characterEncoding = characterEncoding
    }

    public func capabilities(for options: PrintOptions) -> PrintCapabilities {
        var capabilities: PrintCapabilities = [.barcodes]
        if profile.capabilities.contains(.graphicFields) { capabilities.insert(.images) }
        if profile.capabilities.contains(.qrCodes) { capabilities.insert(.qrCodes) }
        if profile.capabilities.contains(.hostStatus) { capabilities.insert(.status) }
        return capabilities
    }

    public func labelMetrics(for options: PrintOptions) throws(PrintError) -> any LabelMetrics {
        try metrics
    }

    public func render(_ label: LaidOutLabel, options: PrintOptions) throws(PrintError) -> RenderedDocument {
        let zplLabel = try self.label(for: label)
        do {
            return RenderedDocument(bytes: try ZPLEncoder(profile: profile).encode(zplLabel))
        } catch {
            throw PrintError(error)
        }
    }

    /// The label as swift-zpl's model, before encoding.
    public func label(for label: LaidOutLabel) throws(PrintError) -> ZPLLabel {
        let renderer = ZPLRenderer(textHeight: try metrics.textHeight)
        return ZPLLabel(
            setup + renderer.commands(for: label),
            quantity: quantity,
            characterEncoding: characterEncoding
        )
    }

    // MARK: - Helpers

    private var metrics: ZPLMetrics {
        get throws(PrintError) {
            let dotsPerMillimeter = profile.resolution.dotsPerMillimeter
            if case .lines = textHeight {
                throw PrintError(delivery: .notSent, reason: .unsupported("a text height in lines"))
            }
            guard let height = textHeight.dots(dotsPerMillimeter: dotsPerMillimeter, lineHeight: 0), height > 0 else {
                throw PrintError(delivery: .notSent, reason: .unsupported("a text height of \(textHeight)"))
            }
            return ZPLMetrics(profile: profile, textHeight: height)
        }
    }
}

extension PrintDriver where Self == ZPLDriver {
    /// A ZPL II printer of this model.
    public static func zpl(
        profile: ZPLProfile,
        textHeight: PrintLength = .millimeters(3.75),
        setup: [ZPLCommand] = [],
        quantity: Int = 1
    ) -> ZPLDriver {
        ZPLDriver(profile: profile, textHeight: textHeight, setup: setup, quantity: quantity)
    }
}

extension PrintError {
    /// The print error for a label swift-zpl refused to encode.
    init(_ error: ZPLEncodingError) {
        if case .unsupported(let missing) = error {
            self.init(delivery: .notSent, reason: .unsupported("ZPL that needs \(missing)"))
        } else {
            self.init(delivery: .notSent, reason: .renderingFailed(String(describing: error)))
        }
    }
}
