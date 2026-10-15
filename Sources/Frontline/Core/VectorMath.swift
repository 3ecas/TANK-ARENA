import CoreGraphics
import Foundation

// CGPoint doubles as a 2D vector throughout the game.
extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint { CGPoint(x: lhs.x * rhs, y: lhs.y * rhs) }
    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint { CGPoint(x: lhs.x / rhs, y: lhs.y / rhs) }
    static func += (lhs: inout CGPoint, rhs: CGPoint) { lhs = lhs + rhs }
    static func -= (lhs: inout CGPoint, rhs: CGPoint) { lhs = lhs - rhs }
    static prefix func - (p: CGPoint) -> CGPoint { CGPoint(x: -p.x, y: -p.y) }

    init(angle: CGFloat, length: CGFloat = 1) {
        self.init(x: cos(angle) * length, y: sin(angle) * length)
    }

    var length: CGFloat { (x * x + y * y).squareRoot() }
    var lengthSquared: CGFloat { x * x + y * y }
    var angle: CGFloat { atan2(y, x) }
    var perpendicular: CGPoint { CGPoint(x: -y, y: x) }

    var normalized: CGPoint {
        let l = length
        return l > 0.0001 ? CGPoint(x: x / l, y: y / l) : .zero
    }

    func distance(to other: CGPoint) -> CGFloat { (self - other).length }
    func distanceSquared(to other: CGPoint) -> CGFloat { (self - other).lengthSquared }
    func dot(_ other: CGPoint) -> CGFloat { x * other.x + y * other.y }

    func clampedLength(_ maxLength: CGFloat) -> CGPoint {
        let l = length
        return l > maxLength && l > 0 ? self * (maxLength / l) : self
    }

    func clamped(to rect: CGRect) -> CGPoint {
        CGPoint(x: x.clamped(rect.minX, rect.maxX), y: y.clamped(rect.minY, rect.maxY))
    }

    func lerp(to other: CGPoint, t: CGFloat) -> CGPoint {
        self + (other - self) * t
    }

    func rotated(by radians: CGFloat) -> CGPoint {
        let c = cos(radians), s = sin(radians)
        return CGPoint(x: x * c - y * s, y: x * s + y * c)
    }

    /// Moves toward `target` by at most `maxDistance`.
    func moved(toward target: CGPoint, maxDistance: CGFloat) -> CGPoint {
        let delta = target - self
        let d = delta.length
        if d <= maxDistance || d < 0.0001 { return target }
        return self + delta * (maxDistance / d)
    }

    /// Returns a point at most `maxDistance` away from `origin` in the direction of self.
    func limited(from origin: CGPoint, maxDistance: CGFloat) -> CGPoint {
        origin + (self - origin).clampedLength(maxDistance)
    }
}

extension CGFloat {
    func clamped(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(self, lower), upper)
    }
}

enum Angle {
    static func normalize(_ a: CGFloat) -> CGFloat {
        var r = a.truncatingRemainder(dividingBy: 2 * .pi)
        if r > .pi { r -= 2 * .pi }
        if r < -.pi { r += 2 * .pi }
        return r
    }

    /// Rotates `current` toward `target` by at most `maxStep` radians.
    static func approach(_ current: CGFloat, _ target: CGFloat, maxStep: CGFloat) -> CGFloat {
        let delta = normalize(target - current)
        if abs(delta) <= maxStep { return target }
        return current + (delta > 0 ? maxStep : -maxStep)
    }
}

enum Geometry {
    /// Shortest distance from `p` to the segment `a`-`b`.
    static func distance(from p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let ab = b - a
        let lenSq = ab.lengthSquared
        if lenSq < 0.0001 { return p.distance(to: a) }
        let t = ((p - a).dot(ab) / lenSq).clamped(0, 1)
        return p.distance(to: a + ab * t)
    }

    /// Random point inside a circle.
    static func randomPoint(in center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let r = radius * CGFloat.random(in: 0...1).squareRoot()
        return center + CGPoint(angle: angle, length: r)
    }
}
