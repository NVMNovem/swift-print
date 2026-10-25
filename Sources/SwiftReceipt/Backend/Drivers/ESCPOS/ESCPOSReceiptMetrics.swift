//
//  ESCPOSReceiptMetrics.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

#if ESCPOS
internal import SwiftESCPOS

/// Widths as an ESC/POS printer sees them: cells from the profile, characters from the code page.
struct ESCPOSReceiptMetrics: TextMetrics {
    let profile: ESCPOSProfile
    let lineWidth: Int
    let codePage: ESCPOSCodePage

    var maximumMagnification: Int {
        Int(profile.maximumMagnification)
    }

    func cellWidth(of font: ReceiptFont) -> Int? {
        switch font {
        case .primary: profile.cellWidths[.a]
        case .secondary: profile.capabilities.contains(.fontB) ? profile.cellWidths[.b] : nil
        }
    }

    func cells(for character: Character) -> Int {
        codePage.encode(String(character)).cellCount
    }
}
#endif
