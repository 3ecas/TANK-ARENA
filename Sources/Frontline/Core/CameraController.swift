import SpriteKit

/// Follows the player's soldier, can be moved freely (minimap) and shakes on big explosions.
@MainActor
final class CameraController {
    let node = SKCameraNode()
    private(set) var isLocked = true
    private(set) var focus: CGPoint
    private let mapSize: CGSize
    private var shakeTime: CGFloat = 0
    private var shakeDuration: CGFloat = 0
    private var shakeMagnitude: CGFloat = 0
    var viewSize: CGSize = CGSize(width: 1280, height: 800)

    init(mapSize: CGSize, start: CGPoint) {
        self.mapSize = mapSize
        self.focus = start
        node.position = start
    }

    var visibleRect: CGRect {
        CGRect(x: focus.x - viewSize.width / 2, y: focus.y - viewSize.height / 2,
               width: viewSize.width, height: viewSize.height)
    }

    func lock() { isLocked = true }

    func moveTo(_ point: CGPoint) {
        isLocked = false
        focus = clampFocus(point)
    }

    func shake(magnitude: CGFloat, duration: CGFloat) {
        if magnitude >= shakeMagnitude || shakeTime <= 0 {
            shakeMagnitude = magnitude
            shakeDuration = duration
            shakeTime = duration
        }
    }

    func update(dt: CGFloat, follow target: CGPoint?) {
        if isLocked, let target = target {
            let t = Swift.min(1, dt * 10)
            focus = clampFocus(focus.lerp(to: target, t: t))
        }
        var offset = CGPoint.zero
        if shakeTime > 0 {
            shakeTime -= dt
            let strength = shakeMagnitude * Swift.max(0, shakeTime / Swift.max(shakeDuration, 0.01))
            offset = CGPoint(x: CGFloat.random(in: -1...1) * strength, y: CGFloat.random(in: -1...1) * strength)
        }
        node.position = focus + offset
    }

    func snap(to point: CGPoint) {
        focus = clampFocus(point)
        node.position = focus
    }

    private func clampFocus(_ p: CGPoint) -> CGPoint {
        let margin: CGFloat = 120
        let halfW = viewSize.width / 2, halfH = viewSize.height / 2
        let x = viewSize.width - margin * 2 >= mapSize.width
            ? mapSize.width / 2 : p.x.clamped(halfW - margin, mapSize.width - halfW + margin)
        let y = viewSize.height - margin * 2 >= mapSize.height
            ? mapSize.height / 2 : p.y.clamped(halfH - margin, mapSize.height - halfH + margin)
        return CGPoint(x: x, y: y)
    }
}
