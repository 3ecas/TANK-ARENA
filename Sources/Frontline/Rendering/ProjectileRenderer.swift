import SpriteKit

/// Keeps one sprite per in-flight projectile.
@MainActor
final class ProjectileRenderer {
    private let layer: SKNode
    private unowned let session: GameSession
    private var sprites: [Int: SKSpriteNode] = [:]

    init(layer: SKNode, session: GameSession) {
        self.layer = layer
        self.session = session
    }

    func update() {
        var live = Set<Int>()
        let vision = session.ctx.vision
        let team = session.player.team
        for projectile in session.world.projectiles where !projectile.isDone {
            live.insert(projectile.id)
            let sprite: SKSpriteNode
            if let existing = sprites[projectile.id] {
                sprite = existing
            } else {
                sprite = TextureFactory.sprite(EffectTextures.projectile(projectile.kind))
                layer.addChild(sprite)
                sprites[projectile.id] = sprite
            }
            sprite.position = projectile.position
            sprite.zRotation = projectile.angle
            sprite.isHidden = !vision.isVisible(projectile.position, to: team)
        }
        for (id, sprite) in sprites where !live.contains(id) {
            sprite.removeFromParent()
            sprites[id] = nil
        }
    }
}
