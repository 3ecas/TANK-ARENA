import CoreGraphics

/// The built-in combat roll every soldier has on F (not a shop ability).
@MainActor
enum DodgeRoll {
    static func isReady(_ hero: Hero) -> Bool {
        hero.isAlive && hero.dodgeCooldown <= 0 && !hero.status.isStunned
    }

    /// Rolls toward `point`. Returns false while on cooldown.
    @discardableResult
    static func perform(_ hero: Hero, toward point: CGPoint) -> Bool {
        guard isReady(hero) else { return false }
        let direction = AbilityGeometry.direction(from: hero.position, to: point, fallbackAngle: hero.bodyAngle)
        hero.status.slowTime = 0
        hero.status.applyDash(velocity: direction * (GameConfig.dodgeDistance / GameConfig.dashDuration),
                              duration: GameConfig.dashDuration)
        hero.dodgeCooldown = GameConfig.dodgeCooldown
        return true
    }
}
