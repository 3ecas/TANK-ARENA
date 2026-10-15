import CoreGraphics
import Foundation

/// Smooth 2D value noise (deterministic per seed), values in 0...1.
struct ValueNoise {
    let seed: UInt32

    func value(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        let x0 = floor(x), y0 = floor(y)
        let fx = x - x0, fy = y - y0
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        let ix = Int32(x0), iy = Int32(y0)
        let a = hash(ix, iy), b = hash(ix + 1, iy), c = hash(ix, iy + 1), d = hash(ix + 1, iy + 1)
        let top = a + (b - a) * sx
        let bottom = c + (d - c) * sx
        return top + (bottom - top) * sy
    }

    private func hash(_ x: Int32, _ y: Int32) -> CGFloat {
        var h = UInt32(bitPattern: x) &* 374_761_393 &+ UInt32(bitPattern: y) &* 668_265_263 &+ seed &* 1_442_695_041
        h = (h ^ (h >> 13)) &* 1_274_126_177
        h ^= h >> 16
        return CGFloat(h & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
}
