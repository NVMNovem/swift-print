//
//  PrintOptions.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// How a print job is produced and finished: the paper and media in the printer, and what is done
/// to them. Never the document's content or layout.
///
/// Options are grouped by layout, so a driver reads only those that apply to what it prints: a
/// receipt driver the ``receipt`` options, a label driver the ``label`` ones. Options a protocol
/// alone has, such as ZPL's media tracking, belong to its driver.
public struct PrintOptions: Sendable, Hashable {
    /// For receipts: the paper roll, the cut and the feed.
    public var receipt: ReceiptOptions
    /// For labels: the media in the printer.
    public var label: LabelOptions

    public init(receipt: ReceiptOptions = ReceiptOptions(), label: LabelOptions = LabelOptions()) {
        self.receipt = receipt
        self.label = label
    }
}

/// How a receipt job is produced: the roll it prints on and what is done after its last line.
///
/// The paper width decides the printable width a ``ReceiptLayoutEngine`` wraps at, so the same
/// receipt prints on 58 mm and 80 mm paper unchanged.
public struct ReceiptOptions: Sendable, Hashable {
    /// The paper roll in the printer.
    public var paperWidth: ReceiptPaperWidth
    /// `nil` feeds without cutting. A cut the printer lacks is replaced by the feed and reported.
    public var cut: ReceiptCut?
    /// Lines fed after the last line, so it clears the cutter or the tear bar.
    public var feedLines: Int

    public init(
        paperWidth: ReceiptPaperWidth = .millimeters80,
        cut: ReceiptCut? = .partial,
        feedLines: Int = 3
    ) {
        self.paperWidth = paperWidth
        self.cut = cut
        self.feedLines = feedLines
    }
}

/// How a label job is produced: the media in the printer.
public struct LabelOptions: Sendable, Hashable {
    /// The label stock in the printer, as configured; `nil` when it is not known. A label larger
    /// than the media is refused. The printer is never asked: this is what the application says is
    /// loaded.
    public var media: LabelMedia?

    public init(media: LabelMedia? = nil) {
        self.media = media
    }
}

/// The size of the label stock loaded in a printer.
public struct LabelMedia: Sendable, Hashable {
    /// The width of one label.
    public var width: PrintLength
    /// The length of one label, or `nil` for continuous media, which has none.
    public var height: PrintLength?

    public init(width: PrintLength, height: PrintLength?) {
        self.width = width
        self.height = height
    }
}
