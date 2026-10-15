import SpriteKit

/// Stays centred on the player's soldier (even at the map edges) and shakes on big explosions.
@MainActor
final class CameraController {
    let node = SKCameraNode()
    private(set) var focus: CGPoint
    private var shakeTime: CGFloat = 0
    private var shakeDuration: CGFloat = 0
    private var shakeMagnitude: CGFloat = 0
    var viewSize: CGSize = CGSize(width: 1280, height: 800)

    init(mapSize: CGSize, start: CGPoint) {
        self.focus = start
        node.position = start
    }

    var visibleRect: CGRect {
        CGRect(x: focus.x - viewSize.width / 2, y: focus.y - viewSize.height / 2,
               width: viewSize.width, height: viewSize.height)
    }

    func shake(magnitude: CGFloat, duration: CGFloat) {
        if magnitude >= shakeMagnitude || shakeTime <= 0 {
            shakeMagnitude = magnitude
            shakeDuration = duration
            shakeTime = duration
        }
    }

    func update(dt: CGFloat, follow target: CGPoint?) {
        if let target = target {
            let t = Swift.min(1, dt * GameConfig.cameraFollowRate)
            focus = focus.lerp(to: target, t: t)
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
        focus = point
        node.position = focus
    }
}
