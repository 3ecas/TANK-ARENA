import SpriteKit

/// Jets and bombers crossing the map for call-ins, with ground shadows.
@MainActor
final class FlyoverRenderer {
    private struct Flyover {
        let plane: SKSpriteNode
        let shadow: SKSpriteNode
        let from: CGPoint
        let to: CGPoint
        let duration: CGFloat
        var age: CGFloat
    }

    private let airLayer: SKNode
    private let shadowLayer: SKNode
    private var flyovers: [Flyover] = []
    private let shadowOffset = CGPoint(x: 40, y: -60)

    init(airLayer: SKNode, shadowLayer: SKNode) {
        self.airLayer = airLayer
        self.shadowLayer = shadowLayer
    }

    func launch(from: CGPoint, to: CGPoint, duration: CGFloat, kind: AircraftPassKind) {
        let count = kind == .bomber ? 3 : 1
        let direction = (to - from).normalized
        for i in 0..<count {
            let lateral = direction.perpendicular * (CGFloat(i) - CGFloat(count - 1) / 2) * 90
            let back = direction * (CGFloat(i % 2) * -60)
            let texture = UnitTextures.aircraft(kind)
            let plane = TextureFactory.sprite(texture)
            plane.zRotation = direction.angle
            airLayer.addChild(plane)
            let size = TextureFactory.size(of: texture)
            let shadow = TextureFactory.sprite(UnitTextures.shadow(width: size.width * 0.9, height: size.height * 0.5))
            shadow.zRotation = direction.angle
            shadowLayer.addChild(shadow)
            flyovers.append(Flyover(plane: plane, shadow: shadow, from: from + lateral + back,
                                    to: to + lateral + back, duration: Swift.max(duration, 0.3), age: 0))
        }
    }

    func update(dt: CGFloat) {
        var i = 0
        while i < flyovers.count {
            flyovers[i].age += dt
            let f = flyovers[i]
            if f.age >= f.duration {
                f.plane.removeFromParent()
                f.shadow.removeFromParent()
                flyovers.remove(at: i)
                continue
            }
            let p = f.from.lerp(to: f.to, t: f.age / f.duration)
            f.plane.position = p
            f.shadow.position = p + shadowOffset
            i += 1
        }
    }
}
