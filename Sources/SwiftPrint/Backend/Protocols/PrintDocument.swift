//
//  PrintDocument.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 27/10/2026.
//

/// Something printed: one receipt or one label, declared like a SwiftUI view.
///
/// A document's ``body`` is its root layout — a ``ReceiptLayout`` or a ``LabelLayout`` — and the
/// layout holds the content. The layout is required and there is only one: the compiler rejects a
/// body that is plain content, and layouts are not content, so none can be nested in another.
///
/// ```swift
/// struct OrderReceipt: PrintDocument {
///     var body: some PrintLayout {
///         ReceiptLayout {
///             Text("Order #42")
///             Divider()
///             Text("Fries")
///         }
///     }
/// }
/// ```
///
/// The document describes content only. The paper, the media, the cut and the feed are the print
/// job's, chosen with ``PrintOptions``, so the same receipt prints on 58 mm and 80 mm paper.
public protocol PrintDocument {
    /// The type of the root layout.
    associatedtype Body: PrintLayout

    /// The root layout, holding the content.
    var body: Body { get }
}

/// How a document's content is placed: a ``ReceiptLayout`` or a ``LabelLayout``.
///
/// A layout is a document's root. It is a document itself, so it can be printed directly, and it
/// is not content, so it cannot be placed inside other content or another layout.
public protocol PrintLayout: PrintDocument where Body == Self {
    /// The layout and its content, resolved. Implemented by the built-in layouts only.
    func _resolved() -> ResolvedDocument
}

extension PrintLayout {
    public var body: Self {
        self
    }
}
