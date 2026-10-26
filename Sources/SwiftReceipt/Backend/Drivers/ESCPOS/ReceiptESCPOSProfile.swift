//
//  ReceiptESCPOSProfile.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

#if ESCPOS
internal import SwiftESCPOS

/// An ESC/POS printer model the driver knows, by its stable identifier.
///
/// The identifier is the one swift-escpos uses (`durapos-dpt201`, `epson-tm`, `generic-escpos`)
/// and may be persisted.
public struct ReceiptESCPOSProfile: Sendable, Hashable, Identifiable {
    /// The swift-escpos identifier.
    public let id: String

    /// The profile with this identifier, or `nil` when swift-escpos does not know it.
    public init?(id: String) {
        guard ESCPOSProfile.builtin(id: id) != nil else { return nil }
        self.id = id
    }

    private init(knownID id: String) {
        self.id = id
    }

    /// A conservative subset for an unknown ESC/POS printer.
    public static let genericESCPOS = ReceiptESCPOSProfile(knownID: ESCPOSProfile.generic.id)
    /// Epson TM-series printers on 80 mm paper.
    public static let epsonTM = ReceiptESCPOSProfile(knownID: ESCPOSProfile.epsonTM.id)
    /// DURAPOS DPT201-URE-BK. Unvalidated until its hardware tests have run.
    public static let duraposDPT201 = ReceiptESCPOSProfile(knownID: ESCPOSProfile.duraposDPT201.id)

    /// The model's name, for people.
    public var name: String {
        escpos.name
    }

    var escpos: ESCPOSProfile {
        ESCPOSProfile.builtin(id: id) ?? .generic
    }
}
#endif
