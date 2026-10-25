//
//  ReceiptDocument+Content.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

extension ReceiptDocument {
    /// The document the content describes.
    public init(_ content: some ReceiptContent) {
        self.init(blocks: Self.blocks(content._receiptNodes().nodes, style: StyleOverride(), alignment: .leading))
    }

    private static func blocks(
        _ nodes: [ReceiptNode],
        style: StyleOverride,
        alignment: ReceiptAlignment
    ) -> [ReceiptBlock] {
        var blocks: [ReceiptBlock] = []
        for node in nodes {
            switch node {
            case .text(let fragments, let own):
                blocks.append(.text(runs(fragments, style: style), alignment: own ?? alignment))
            case .spacer:
                continue
            case .divider(let character):
                blocks.append(.divider(character, style: style.resolved))
            case .feed(let lines):
                blocks.append(.spacing(lines: lines))
            case .image(let image):
                blocks.append(.image(image, alignment: alignment))
            case .qrCode(let code):
                blocks.append(.qrCode(code, alignment: alignment))
            case .stack(let children, let spacing):
                var isFirst = true
                for child in children {
                    let childBlocks = Self.blocks([child], style: style, alignment: alignment)
                    guard !childBlocks.isEmpty else { continue }
                    if !isFirst, spacing > 0 { blocks.append(.spacing(lines: spacing)) }
                    blocks += childBlocks
                    isFirst = false
                }
            case .row(let children):
                blocks += row(children, style: style, alignment: alignment)
            case .styled(let override, let own, let children):
                blocks += Self.blocks(children, style: override.filling(from: style), alignment: own ?? alignment)
            }
        }
        return blocks
    }

    /// A row's text columns, split at the first spacer, followed by anything that is not text.
    private static func row(
        _ children: [ReceiptNode],
        style: StyleOverride,
        alignment: ReceiptAlignment
    ) -> [ReceiptBlock] {
        var leading: [[StyledRun]] = []
        var trailing: [[StyledRun]] = []
        var hasPassedSpacer = false
        var extras: [ReceiptBlock] = []

        func collect(_ nodes: [ReceiptNode], style: StyleOverride, alignment: ReceiptAlignment) {
            for node in nodes {
                switch node {
                case .text(let fragments, _):
                    let column = runs(fragments, style: style)
                    if hasPassedSpacer { trailing.append(column) } else { leading.append(column) }
                case .spacer:
                    hasPassedSpacer = true
                case .styled(let override, let own, let children):
                    collect(children, style: override.filling(from: style), alignment: own ?? alignment)
                case .stack(let children, _), .row(let children):
                    collect(children, style: style, alignment: alignment)
                case .divider, .feed, .image, .qrCode:
                    extras += blocks([node], style: style, alignment: alignment)
                }
            }
        }
        collect(children, style: style, alignment: alignment)

        let row: [ReceiptBlock] = leading.isEmpty && trailing.isEmpty
            ? []
            : [.row(ReceiptRow(leading: leading, trailing: trailing))]
        return row + extras
    }

    private static func runs(_ fragments: [TextFragment], style: StyleOverride) -> [StyledRun] {
        fragments.map { StyledRun($0.string, style: $0.style.filling(from: style).resolved) }
    }
}
