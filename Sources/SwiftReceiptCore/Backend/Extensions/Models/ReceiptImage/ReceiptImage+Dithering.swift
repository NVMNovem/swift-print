//
//  ReceiptImage+Dithering.swift
//  swift-receipt
//
//  Created by Damian Van de Kauter on 25/10/2026.
//

extension ReceiptImage {
    /// The image at `width` dots, its height scaled to keep the proportions, dithered to 1 bit.
    ///
    /// Each target pixel averages the source pixels it covers, then Floyd–Steinberg error
    /// diffusion in integer arithmetic decides the dots. The same image always gives the same dots.
    public func bitmap(width targetWidth: Int) -> ReceiptBitmap {
        let targetWidth = max(1, targetWidth)
        let targetHeight = max(1, (height * targetWidth + width / 2) / width)
        var gray = scaled(toWidth: targetWidth, height: targetHeight)

        let bytesPerRow = (targetWidth + 7) / 8
        var packed = [UInt8](repeating: 0, count: bytesPerRow * targetHeight)
        for y in 0..<targetHeight {
            for x in 0..<targetWidth {
                let index = y * targetWidth + x
                let old = gray[index]
                let new = old < 128 ? 0 : 255
                if new == 0 {
                    packed[y * bytesPerRow + x / 8] |= 0x80 >> UInt8(x % 8)
                }
                let error = old - new
                func spread(_ dx: Int, _ dy: Int, _ weight: Int) {
                    let nx = x + dx, ny = y + dy
                    guard nx >= 0, nx < targetWidth, ny < targetHeight else { return }
                    gray[ny * targetWidth + nx] += error * weight / 16
                }
                spread(1, 0, 7)
                spread(-1, 1, 3)
                spread(0, 1, 5)
                spread(1, 1, 1)
            }
        }
        return ReceiptBitmap(width: targetWidth, height: targetHeight, packedRows: packed)!
    }

    /// Box-averaged grayscale at the target size, as `Int`s so error diffusion can overshoot.
    private func scaled(toWidth targetWidth: Int, height targetHeight: Int) -> [Int] {
        var result = [Int](repeating: 255, count: targetWidth * targetHeight)
        for ty in 0..<targetHeight {
            let y0 = ty * height / targetHeight
            let y1 = max(y0 + 1, (ty + 1) * height / targetHeight)
            for tx in 0..<targetWidth {
                let x0 = tx * width / targetWidth
                let x1 = max(x0 + 1, (tx + 1) * width / targetWidth)
                var sum = 0
                for y in y0..<y1 {
                    for x in x0..<x1 {
                        sum += Int(pixels[y * width + x])
                    }
                }
                result[ty * targetWidth + tx] = sum / ((y1 - y0) * (x1 - x0))
            }
        }
        return result
    }
}
