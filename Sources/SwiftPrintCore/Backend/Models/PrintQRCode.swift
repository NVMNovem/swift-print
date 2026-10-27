//
//  PrintQRCode.swift
//  swift-print
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

/// A QR code, by meaning. The driver draws it with the printer's own command.
public struct PrintQRCode: Sendable, Hashable {
    /// The share of the symbol that may be damaged and still read.
    public enum ErrorCorrection: Sendable, Hashable, CaseIterable {
        /// About 7 %.
        case low
        /// About 15 %.
        case medium
        /// About 25 %.
        case quartile
        /// About 30 %.
        case high
    }

    /// The text the code holds, such as a URL.
    public var payload: String
    /// Dots per module.
    public var moduleSize: Int
    /// How much damage the code survives.
    public var errorCorrection: ErrorCorrection

    public init(_ payload: String, moduleSize: Int = 6, errorCorrection: ErrorCorrection = .medium) {
        self.payload = payload
        self.moduleSize = moduleSize
        self.errorCorrection = errorCorrection
    }
}

extension PrintQRCode {
    /// The modules along one side of the symbol, quiet zone excluded, or `nil` when the payload is
    /// more than a QR code holds at this error correction.
    ///
    /// Counted as if the payload were stored byte by byte in UTF-8, the largest a printer's encoding
    /// makes it, so a printer that packs digits or letters may draw a smaller symbol, never a larger.
    public var moduleCount: Int? {
        let byteCount = payload.utf8.count
        let column = switch errorCorrection {
        case .low: 0
        case .medium: 1
        case .quartile: 2
        case .high: 3
        }
        guard let index = Self.byteCapacities.firstIndex(where: { $0[column] >= byteCount }) else {
            return nil
        }
        return 17 + 4 * (index + 1)
    }

    /// Bytes a symbol of each version, 1 to 40, holds in byte mode at L, M, Q and H.
    private static let byteCapacities: [[Int]] = [
        [17, 14, 11, 7], [32, 26, 20, 14], [53, 42, 32, 24], [78, 62, 46, 34],
        [106, 84, 60, 44], [134, 106, 74, 58], [154, 122, 86, 64], [192, 152, 108, 84],
        [230, 180, 130, 98], [271, 213, 151, 119], [321, 251, 177, 137], [367, 287, 203, 155],
        [425, 331, 241, 177], [458, 362, 258, 194], [520, 412, 292, 220], [586, 450, 322, 250],
        [644, 504, 364, 280], [718, 560, 394, 310], [792, 624, 442, 338], [858, 666, 482, 382],
        [929, 711, 509, 403], [1003, 779, 565, 439], [1091, 857, 611, 461], [1171, 911, 661, 511],
        [1273, 997, 715, 535], [1367, 1059, 751, 593], [1465, 1125, 805, 625], [1528, 1190, 868, 658],
        [1628, 1264, 908, 698], [1732, 1370, 982, 742], [1840, 1452, 1030, 790], [1952, 1538, 1112, 842],
        [2068, 1628, 1168, 898], [2188, 1722, 1228, 958], [2303, 1809, 1283, 983], [2431, 1911, 1351, 1051],
        [2563, 1989, 1423, 1093], [2699, 2099, 1499, 1139], [2809, 2213, 1579, 1219], [2953, 2331, 1663, 1273],
    ]
}
