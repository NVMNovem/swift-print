//
//  Image.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A picture, scaled down to the width it has and dithered, one dot per pixel. Left off, and
/// reported, on a receipt printer without images; refused on a label printer without them.
public struct Image: PrintContent {
    let image: PrintImage

    /// The picture, as grayscale pixels.
    public init(_ image: PrintImage) {
        self.image = image
    }

    public var body: Never {
        return fatalError("Image has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        _PrintNodes([.image(image)])
    }
}
