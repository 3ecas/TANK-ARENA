import SpriteKit

/// SpriteKit representation of one entity. Reads entity state, never writes it.
@MainActor
final class EntityView {
    let root = SKNode()
    let body: SKSpriteNode
    var turret: SKSpriteNode?
    var shadow: SKSpriteNode?
    var rotor: SKSpriteNode?
    var healthBar: HealthBarNode?
    var label: SKLabelNode?
    /// Infantry turn their whole body toward their aim.
    var bodyFollowsAim = false
    var altitude: CGFloat = 0
    private var lastFraction: CGFloat = -1
    private var lastInvulnerable = false
    private var lastLevel = 0

    init(body: SKSpriteNode) {
        self.body = body
        root.addChild(body)
    }

    func sync(with entity: Entity, dt: CGFloat) {
        root.position = entity.position
        if bodyFollowsAim {
            let aiming = entity is Hero || entity.timeSinceShot < 1.2
            body.zRotation = aiming ? entity.aimAngle : entity.bodyAngle
        } else {
            body.zRotation = entity.bodyAngle
        }
        if let turret = turret {
            turret.zRotation = entity.aimAngle
        }
        if let rotor = rotor {
            rotor.zRotation += dt * 28
        }
        // Stunned (EMP) units are tinted blue.
        let stunned = entity.status.isStunned
        body.colorBlendFactor = stunned ? 0.55 : 0
        turret?.colorBlendFactor = body.colorBlendFactor
        // Summons blink when about to expire.
        if let life = entity.lifetime, life < 3 {
            root.alpha = 0.55 + 0.45 * abs(sin(life * 10))
        } else {
            root.alpha = 1
        }
        let fraction = entity.hpFraction
        if abs(fraction - lastFraction) > 0.001 || entity.isInvulnerable != lastInvulnerable {
            lastFraction = fraction
            lastInvulnerable = entity.isInvulnerable
            healthBar?.setFraction(fraction, invulnerable: entity.isInvulnerable)
        }
        if let hero = entity as? Hero, hero.level != lastLevel {
            lastLevel = hero.level
            label?.text = "\(hero.name)  Lv \(hero.level)"
        }
    }
}
