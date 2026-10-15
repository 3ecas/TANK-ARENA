import SpriteKit

/// SpriteKit representation of one soldier. Reads soldier state, never writes it.
@MainActor
final class SoldierView {
    let root = SKNode()
    private let body: SKSpriteNode
    private let knife: SKSpriteNode
    private let healthBar: HealthBarNode
    private var weaponShown: WeaponID
    private let team: Team
    private var lastFraction: CGFloat = -1

    init(soldier: Soldier, friendly: Bool) {
        team = soldier.team
        weaponShown = soldier.activeWeapon.def.id
        body = TextureFactory.sprite(SoldierTextures.soldier(team: soldier.team, weapon: weaponShown))
        body.anchorPoint = CGPoint(x: 15.0 / 40.0, y: 0.5)
        body.color = SKColor(red: 0.4, green: 0.7, blue: 1, alpha: 1)
        knife = TextureFactory.sprite(SoldierTextures.knifeArc())
        knife.isHidden = true
        let color = soldier.isPlayer ? Palette.player : (friendly ? Palette.team(.blue) : Palette.team(.red))
        healthBar = HealthBarNode(width: 26, height: 3, color: color)
        healthBar.position = CGPoint(x: 0, y: 20)
        healthBar.zPosition = 5
        if soldier.isPlayer {
            let ring = TextureFactory.sprite(EffectTextures.ring(radius: 20, lineWidth: 2))
            ring.color = Palette.player
            ring.colorBlendFactor = 1
            ring.alpha = 0.7
            ring.zPosition = -1
            root.addChild(ring)
        }
        root.addChild(body)
        root.addChild(knife)
        root.addChild(healthBar)
    }

    func sync(with soldier: Soldier) {
        root.position = soldier.position
        body.zRotation = soldier.facing
        let weapon = soldier.activeWeapon.def.id
        if weapon != weaponShown {
            weaponShown = weapon
            body.texture = SoldierTextures.soldier(team: team, weapon: weapon)
        }
        body.colorBlendFactor = soldier.isStunned ? 0.6 : 0
        root.alpha = soldier.spawnProtection > 0 ? 0.5 + 0.3 * sin(soldier.spawnProtection * 20) : 1
        knife.isHidden = soldier.knifeSwing <= 0
        knife.zRotation = soldier.facing + (0.2 - soldier.knifeSwing) * 4
        let fraction = soldier.hpFraction
        if abs(fraction - lastFraction) > 0.001 {
            lastFraction = fraction
            healthBar.setFraction(fraction, invulnerable: false)
            healthBar.isHidden = fraction >= 1
        }
    }
}
