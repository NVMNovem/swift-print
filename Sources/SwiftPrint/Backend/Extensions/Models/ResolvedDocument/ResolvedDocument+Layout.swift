//
//  ResolvedDocument+Layout.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

extension ResolvedDocument {
    /// The document resolved through its root layout: the layout's format, and its content with
    /// every style and alignment resolved onto the text, pictures and codes.
    public init(_ document: some PrintDocument) {
        self = document.body._resolved()
    }

    /// A layout's format and content nodes, resolved.
    init(format: Format, nodes: [PrintNode]) {
        self.init(format: format, content: Self.elements(nodes, style: StyleOverride(), alignment: .leading))
    }

    private static func elements(
        _ nodes: [PrintNode],
        style: StyleOverride,
        alignment: PrintAlignment
    ) -> [PrintElement] {
        var elements: [PrintElement] = []
        for node in nodes {
            switch node {
            case .text(let fragments, let own):
                elements.append(.text(runs(fragments, style: style), alignment: own ?? alignment))
            case .spacer:
                elements.append(.spacer)
            case .divider(let character):
                elements.append(.divider(character, style: style.resolved))
            case .feed(let lines):
                elements.append(.feed(lines: lines))
            case .image(let image):
                elements.append(.image(image, alignment: alignment))
            case .qrCode(let code):
                elements.append(.qrCode(code, alignment: alignment))
            case .barcode(let barcode):
                elements.append(.barcode(barcode, alignment: alignment))
            case .stack(let children, let spacing):
                elements.append(.verticalStack(Self.elements(children, style: style, alignment: alignment), spacing: spacing))
            case .row(let children):
                elements.append(.horizontalStack(Self.elements(children, style: style, alignment: alignment), alignment: alignment))
            case .styled(let override, let own, let children):
                let inner = Self.elements(children, style: override.filling(from: style), alignment: own ?? alignment)
                elements += inner.count > 1 ? [.verticalStack(inner, spacing: .zero)] : inner
            case .padding(let insets, let children):
                let inner = Self.elements(children, style: style, alignment: alignment)
                elements.append(.padding(insets, inner.count == 1 ? inner[0] : .verticalStack(inner, spacing: .zero)))
            }
        }
        return elements
    }

    private static func runs(_ fragments: [TextFragment], style: StyleOverride) -> [StyledRun] {
        fragments.map { StyledRun($0.string, style: $0.style.filling(from: style).resolved) }
    }
}
