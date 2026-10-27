//
//  Image.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A picture, scaled to the paper and dithered. Left off, and reported, on a printer without images.
public struct Image: ReceiptContent {
    let image: ReceiptImage

    /// The picture, as grayscale pixels.
    public init(_ image: ReceiptImage) {
        self.image = image
    }

    public var body: Never {
        return fatalError("Image has no body.")
    }

    public func _receiptNodes() -> _ReceiptNodes {
        _ReceiptNodes([.image(image)])
    }
}
