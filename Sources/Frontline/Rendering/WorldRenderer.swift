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
        buildTree()
    }

    private func buildTree() {
        let map = session.world.map
        let ground = SKSpriteNode(texture: ArenaPainter.texture(for: map), size: map.size)
        ground.anchorPoint = .zero
        ground.zPosition = 0
        root.addChild(ground)
        let layers: [(SKNode, CGFloat)] = [(decalLayer, 1), (unitLayer, 10), (grenadeLayer, 15), (effectLayer, 20)]
        for (layer, z) in layers {
            layer.zPosition = z
            root.addChild(layer)
        }
    }

    func update(dt: CGFloat) {
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
            let shown = isShown(soldier)
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
