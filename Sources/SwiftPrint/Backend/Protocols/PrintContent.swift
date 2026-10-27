//
//  PrintContent.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A piece of printed content, declared like a SwiftUI view.
///
/// A conforming type describes its content in ``body``; the framework turns it into a
/// ``PrintDocument`` immediately and keeps nothing else. There is no state, no environment and no
/// identity: a receipt or a label is a function of its input, so the same input always prints the
/// same bytes. Content placed in a ``LabelLayout`` prints as a label; any other content as a receipt.
public protocol PrintContent {
    /// The type of content this content is made of.
    associatedtype Body: PrintContent

    /// The content this content is made of.
    @PrintBuilder var body: Body { get }

    /// The content as the framework's internal nodes. Implemented by the built-in content only.
    func _printNodes() -> _PrintNodes
}

extension PrintContent {
    public func _printNodes() -> _PrintNodes {
        body._printNodes()
    }
}

extension Never: PrintContent {
    public var body: Never {
        return fatalError("Never has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        fatalError("Never has no content.")
    }
}
