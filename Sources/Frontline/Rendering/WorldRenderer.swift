import SpriteKit

/// Owns the world-space node tree and keeps it in sync with the game state each frame.
@MainActor
final class WorldRenderer {
    let root = SKNode()
    /// World-space layer for UI overlays (target ring, reticles) above the fog.
    let overlayLayer: SKNode
    let effects: EffectsRenderer

    private unowned let session: GameSession
    private let decalLayer: SKNode
    private let zoneLayer: SKNode
    private let unitLayer: SKNode
    private let projectileLayer: SKNode
    private let effectLayer: SKNode
    private let shadowLayer: SKNode
    private let airLayer: SKNode
    private let textLayer: SKNode
    private var views: [Int: EntityView] = [:]
    private let projectiles: ProjectileRenderer
    private let strikes: StrikeRenderer
    private let zones: ZoneRenderer
    private let objectives: ObjectiveRenderer
    private let fog: FogRenderer

    init(session: GameSession) {
        let decal = SKNode(), zone = SKNode(), unit = SKNode(), projectile = SKNode(), effect = SKNode()
        let shadow = SKNode(), air = SKNode(), overlay = SKNode(), text = SKNode()
        self.session = session
        decalLayer = decal
        zoneLayer = zone
        unitLayer = unit
        projectileLayer = projectile
        effectLayer = effect
        shadowLayer = shadow
        airLayer = air
        overlayLayer = overlay
        textLayer = text
        projectiles = ProjectileRenderer(layer: projectile, session: session)
        strikes = StrikeRenderer(layer: overlay, session: session)
        zones = ZoneRenderer(layer: zone, session: session)
        objectives = ObjectiveRenderer(layer: decal, session: session)
        fog = FogRenderer(session: session)
        effects = EffectsRenderer(session: session, effectLayer: effect, decalLayer: decal,
                                  textLayer: text, airLayer: air, shadowLayer: shadow)
        buildTree()
    }

    private func buildTree() {
        let map = SKSpriteNode(texture: MapTextureBuilder.texture(for: session.world.map, city: session.world.city),
                               size: CGSize(width: session.world.map.size, height: session.world.map.size))
        map.anchorPoint = .zero
        map.zPosition = 0
        root.addChild(map)
        let layers: [(SKNode, CGFloat)] = [
            (decalLayer, 1), (zoneLayer, 2), (unitLayer, 10), (projectileLayer, 20), (effectLayer, 25),
            (shadowLayer, 28), (airLayer, 30), (fog.node, 40), (overlayLayer, 45), (textLayer, 50),
        ]
        for (layer, z) in layers {
            layer.zPosition = z
            root.addChild(layer)
        }
    }

    /// Current fog texture (shared with the minimap).
    var fogTexture: SKTexture? { fog.node.texture }

    func update(dt: CGFloat) {
        syncEntities(dt: dt)
        projectiles.update()
        strikes.update(dt: dt)
        zones.update(dt: dt)
        objectives.update()
        fog.update()
        effects.update(dt: dt)
    }

    private func syncEntities(dt: CGFloat) {
        let world = session.world
        let vision: VisionSystem = session.ctx.vision
        let team = session.player.team
        var live = Set<Int>()
        for entity in world.entities where !entity.isRemoved {
            live.insert(entity.id)
            let view = views[entity.id] ?? makeView(for: entity)
            let visible = entity.isAlive && vision.canSee(team, entity)
            view.root.isHidden = !visible
            if visible { view.sync(with: entity, dt: dt) }
        }
        for (id, view) in views where !live.contains(id) {
            view.root.removeFromParent()
            views[id] = nil
        }
    }

    private func makeView(for entity: Entity) -> EntityView {
        let isPlayer = entity === session.player
        let view = EntityViewFactory.makeView(for: entity, playerTeam: session.player.team, isPlayer: isPlayer)
        if entity is Structure {
            view.root.zPosition = -1
        } else if entity is Hero {
            view.root.zPosition = isPlayer ? 2 : 1
        }
        (entity.isFlying ? airLayer : unitLayer).addChild(view.root)
        views[entity.id] = view
        return view
    }
}
