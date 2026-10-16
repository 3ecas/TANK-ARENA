import SpriteKit

/// Owns the world-space node tree and keeps it in sync with the battle each frame.
/// Enemies are only drawn while the viewer has line of sight to them.
@MainActor
final class WorldRenderer {
    let root = SKNode()
    let effects: EffectsRenderer
    private unowned let session: GameSession
    private let decalLayer: SKNode
    private let unitLayer: SKNode
    private let grenadeLayer: SKNode
    private let effectLayer: SKNode
    private let siteRenderer: SiteRenderer
    private let rangeIndicator = RangeIndicator()
    private let vehicleRenderer = VehicleRenderer()
    private let supplyRenderer = SupplyRenderer()
    private var views: [Int: SoldierView] = [:]
    private var grenadeSprites: [Int: SKSpriteNode] = [:]

    init(session: GameSession) {
        let decal = SKNode(), unit = SKNode(), grenade = SKNode(), effect = SKNode()
        self.session = session
        decalLayer = decal
        unitLayer = unit
        grenadeLayer = grenade
        effectLayer = effect
        effects = EffectsRenderer(session: session, effectLayer: effect, decalLayer: decal)
        siteRenderer = SiteRenderer(world: session.world, playerTeam: session.player.team)
        buildTree()
    }

    private func buildTree() {
        let map = session.world.map
        let ground = SKSpriteNode(texture: ArenaPainter.texture(for: map), size: map.size)
        ground.anchorPoint = .zero
        ground.zPosition = 0
        root.addChild(ground)
        siteRenderer.root.zPosition = 0.5
        root.addChild(siteRenderer.root)
        rangeIndicator.root.zPosition = 9
        root.addChild(rangeIndicator.root)
        supplyRenderer.root.zPosition = 2
        root.addChild(supplyRenderer.root)
        vehicleRenderer.root.zPosition = 12
        root.addChild(vehicleRenderer.root)
        let layers: [(SKNode, CGFloat)] = [(decalLayer, 1), (unitLayer, 10), (grenadeLayer, 15), (effectLayer, 20)]
        for (layer, z) in layers {
            layer.zPosition = z
            root.addChild(layer)
        }
    }

    func update(dt: CGFloat) {
        siteRenderer.update(dt: dt, world: session.world, isShown: { [unowned self] in self.isShown($0) },
                            canSee: { [unowned self] in self.canSee($0) })
        rangeIndicator.update(player: session.player, map: session.world.map)
        vehicleRenderer.update(dt: dt, world: session.world, playerTeam: session.player.team,
                               isShown: { [unowned self] in self.isShown($0) })
        supplyRenderer.update(world: session.world, playerTeam: session.player.team)
        syncSoldiers()
        syncGrenades()
        effects.update(dt: dt)
    }

    /// Whether the player's side can currently see this soldier.
    func isShown(_ soldier: Soldier) -> Bool {
        guard soldier.isAlive else { return false }
        if soldier.team == session.player.team || session.viewer == nil { return true }
        return session.vision.visibleToViewer.contains(soldier.id)
    }

    /// Whether the viewer has a line of sight to a point within view range (used for a dropped bomb).
    func canSee(_ point: CGPoint) -> Bool {
        guard let viewer = session.viewer else { return false }
        return viewer.position.distance(to: point) <= GameConfig.visionRange
            && session.world.map.hasLineOfSight(viewer.position, point)
    }

    private func syncSoldiers() {
        for soldier in session.world.soldiers {
            let view: SoldierView
            if let existing = views[soldier.id] {
                view = existing
            } else {
                view = SoldierView(soldier: soldier, friendly: soldier.team == session.player.team)
                view.root.zPosition = soldier.isPlayer ? 2 : 0
                unitLayer.addChild(view.root)
                views[soldier.id] = view
            }
            // Pilots are drawn as their vehicle; downed teammates stay visible so medics can find them.
            let downedMate = soldier.isDowned && soldier.team == session.player.team
            let shown = (isShown(soldier) && !soldier.isMounted) || downedMate
            view.root.isHidden = !shown
            if shown { view.sync(with: soldier) }
        }
    }

    private func syncGrenades() {
        var live = Set<Int>()
        for grenade in session.world.grenades where !grenade.isDone {
            live.insert(grenade.id)
            let sprite: SKSpriteNode
            if let existing = grenadeSprites[grenade.id] {
                sprite = existing
            } else {
                sprite = TextureFactory.sprite(SoldierTextures.grenade(grenade.type))
                grenadeLayer.addChild(sprite)
                grenadeSprites[grenade.id] = sprite
            }
            sprite.position = grenade.position
            sprite.zRotation += grenade.remainingDistance > 0 ? 0.3 : 0
        }
        for (id, sprite) in grenadeSprites where !live.contains(id) {
            sprite.removeFromParent()
            grenadeSprites[id] = nil
        }
    }
}
