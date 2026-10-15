import SpriteKit

/// Smoke clouds, shield domes, supply crates and UAV reveal circles.
@MainActor
final class ZoneRenderer {
    @MainActor
    private final class ZoneView {
        let root = SKNode()
        var crate: SKSpriteNode?
        var initialValue: CGFloat = 1
    }

    private let layer: SKNode
    private unowned let session: GameSession
    private var views: [Int: ZoneView] = [:]

    init(layer: SKNode, session: GameSession) {
        self.layer = layer
        self.session = session
    }

    func update(dt: CGFloat) {
        var live = Set<Int>()
        for zone in session.world.zones where !zone.isDone {
            if zone.kind == .uavReveal && zone.team != session.player.team { continue }
            live.insert(zone.id)
            let view = views[zone.id] ?? makeView(for: zone)
            sync(view, zone: zone, dt: dt)
        }
        for (id, view) in views where !live.contains(id) {
            view.root.removeFromParent()
            views[id] = nil
        }
    }

    private func sync(_ view: ZoneView, zone: AreaZone, dt: CGFloat) {
        let fadeOut = Swift.min(1, zone.remaining / 0.8)
        switch zone.kind {
        case .smoke:
            view.root.zRotation += dt * 0.15
            view.root.alpha = fadeOut
        case .shieldDome:
            view.root.alpha = (0.35 + 0.65 * (zone.value / Swift.max(view.initialValue, 1))) * fadeOut
        case .supplyCrate:
            if zone.armingDelay > 0 {
                let t = zone.armingDelay / GameConfig.supplyDropDelay
                view.crate?.setScale(1 + 1.8 * t)
                view.crate?.alpha = 1 - t * 0.5
            } else {
                view.crate?.setScale(1)
                view.root.alpha = fadeOut
            }
        case .uavReveal:
            view.root.zRotation -= dt * 0.6
            view.root.alpha = fadeOut
        }
    }

    private func makeView(for zone: AreaZone) -> ZoneView {
        let view = ZoneView()
        view.root.position = zone.center
        view.initialValue = zone.value
        let diameter = zone.radius * 2
        switch zone.kind {
        case .smoke:
            for i in 0..<8 {
                let offset = i == 0 ? CGPoint.zero : CGPoint(angle: CGFloat(i) * .pi / 3.5, length: zone.radius * 0.5)
                let puff = SKSpriteNode(texture: EffectTextures.puff,
                                        size: CGSize(width: zone.radius * 1.3, height: zone.radius * 1.3))
                puff.position = offset
                puff.color = SKColor(white: 0.78, alpha: 1)
                puff.colorBlendFactor = 1
                view.root.addChild(puff)
            }
        case .shieldDome:
            view.root.addChild(tinted(EffectTextures.disc, diameter, SKColor(red: 0.3, green: 0.75, blue: 1, alpha: 1), 0.22))
            view.root.addChild(ring(zone.radius, SKColor(red: 0.5, green: 0.9, blue: 1, alpha: 1), 0.9))
        case .supplyCrate:
            view.root.addChild(ring(zone.radius, Palette.heal, 0.7))
            let crate = TextureFactory.sprite(StructureTextures.crate())
            view.root.addChild(crate)
            view.crate = crate
        case .uavReveal:
            view.root.addChild(ring(zone.radius, Palette.heal, 0.35))
            let drone = TextureFactory.sprite(UnitTextures.aircraft(.jet))
            drone.setScale(0.45)
            drone.position = CGPoint(x: 0, y: zone.radius * 0.35)
            drone.zRotation = .pi
            view.root.addChild(drone)
        }
        layer.addChild(view.root)
        views[zone.id] = view
        return view
    }

    private func tinted(_ texture: SKTexture, _ diameter: CGFloat, _ color: SKColor, _ alpha: CGFloat) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture, size: CGSize(width: diameter, height: diameter))
        node.color = color
        node.colorBlendFactor = 1
        node.alpha = alpha
        return node
    }

    private func ring(_ radius: CGFloat, _ color: SKColor, _ alpha: CGFloat) -> SKSpriteNode {
        let texture = EffectTextures.ring(radius: radius, lineWidth: 4)
        let node = SKSpriteNode(texture: texture, size: TextureFactory.size(of: texture))
        node.color = color
        node.colorBlendFactor = 1
        node.alpha = alpha
        return node
    }
}
