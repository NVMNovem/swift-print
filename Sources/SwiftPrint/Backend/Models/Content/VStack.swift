//
//  VStack.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// Content placed one piece under the other, `spacing` apart.
///
/// On a receipt the spacing is whole lines: ``PrintLength/lines(_:)`` as given, a physical length
/// rounded up to the lines it needs. On a label it is exact, and ``Spacer``s share the height the
/// stack has left.
public struct VStack: PrintContent {
    let children: [PrintNode]
    let spacing: PrintLength
    let alignment: PrintAlignment?

    /// The content one piece under the other, `spacing` apart.
    ///
    /// - Parameters:
    ///   - alignment: Where text, pictures and codes inside sit across the width, when they have not
    ///     chosen their own; the same as ``PrintContent/alignment(_:)``.
    ///   - spacing: The space between pieces. An integer is a number of dots; on a receipt, use
    ///     ``PrintLength/lines(_:)``.
    public init<Content: PrintContent>(
        alignment: PrintAlignment? = nil,
        spacing: PrintLength = .zero,
        @PrintBuilder content: () -> Content
    ) {
        self.children = content()._printNodes().nodes
        self.spacing = spacing
        self.alignment = alignment
    }

    public var body: Never {
        return fatalError("VStack has no body.")
    }

    public func _printNodes() -> _PrintNodes {
        let stack = PrintNode.stack(children, spacing: spacing)
        guard let alignment else { return _PrintNodes([stack]) }
        return _PrintNodes([.styled(StyleOverride(), alignment: alignment, [stack])])
    }
}
