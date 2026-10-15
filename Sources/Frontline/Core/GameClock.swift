import Foundation
import CoreGraphics

/// Converts SpriteKit's absolute frame time into a clamped delta time.
struct GameClock {
    /// Longest step simulated in one frame (prevents tunnelling after a hitch).
    static let maxStep: CGFloat = 1.0 / 20.0
    private var lastTime: TimeInterval?

    mutating func tick(_ now: TimeInterval) -> CGFloat {
        defer { lastTime = now }
        guard let last = lastTime else { return 0 }
        return CGFloat(now - last).clamped(0, GameClock.maxStep)
    }

    mutating func reset() {
        lastTime = nil
    }
}
