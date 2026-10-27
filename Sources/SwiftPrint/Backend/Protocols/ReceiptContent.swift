//
//  ReceiptContent.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A piece of a receipt, declared like a SwiftUI view.
///
/// A conforming type describes its content in ``body``; the framework turns it into a
/// ``ReceiptDocument`` immediately and keeps nothing else. There is no state, no environment and no
/// identity: a receipt is a function of its input, so the same input always prints the same bytes.
public protocol ReceiptContent {
    /// The type of content this content is made of.
    associatedtype Body: ReceiptContent

    /// The content this content is made of.
    @ReceiptBuilder var body: Body { get }

    /// The content as the framework's internal nodes. Implemented by the built-in content only.
    func _receiptNodes() -> _ReceiptNodes
}

extension ReceiptContent {
    public func _receiptNodes() -> _ReceiptNodes {
        body._receiptNodes()
    }
}

extension Never: ReceiptContent {
    public var body: Never {
        return fatalError("Never has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        fatalError("Never has no content.")
    }
}
