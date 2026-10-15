import CoreGraphics

/// Timed buffs and debuffs on a unit. Ticked by `StatusEffectSystem`.
struct StatusEffects {
    var slowAmount: CGFloat = 0
    var slowTime: CGFloat = 0
    var stunTime: CGFloat = 0
    var speedBoost: CGFloat = 0
    var speedBoostTime: CGFloat = 0
    var fireRateBoost: CGFloat = 0
    var fireRateBoostTime: CGFloat = 0
    var healPerSecond: CGFloat = 0
    var healTime: CGFloat = 0
    var dashVelocity: CGPoint = .zero
    var dashTime: CGFloat = 0

    var isStunned: Bool { stunTime > 0 }
    var isDashing: Bool { dashTime > 0 }

    var speedMultiplier: CGFloat {
        let slow = slowTime > 0 ? slowAmount : 0
        let boost = speedBoostTime > 0 ? speedBoost : 0
        return Swift.max(0.1, (1 - slow) * (1 + boost))
    }

    var fireRateMultiplier: CGFloat {
        fireRateBoostTime > 0 ? 1 + fireRateBoost : 1
    }

    mutating func applySlow(_ amount: CGFloat, duration: CGFloat) {
        slowAmount = Swift.max(slowTime > 0 ? slowAmount : 0, amount)
        slowTime = Swift.max(slowTime, duration)
    }

    mutating func applyStun(duration: CGFloat) {
        stunTime = Swift.max(stunTime, duration)
    }

    mutating func applySpeedBoost(_ amount: CGFloat, duration: CGFloat) {
        speedBoost = amount
        speedBoostTime = Swift.max(speedBoostTime, duration)
    }

    mutating func applyFireRateBoost(_ amount: CGFloat, duration: CGFloat) {
        fireRateBoost = amount
        fireRateBoostTime = Swift.max(fireRateBoostTime, duration)
    }

    /// Adds a heal-over-time; overlapping heals stack their remaining amounts.
    mutating func applyHeal(total: CGFloat, duration: CGFloat) {
        let remaining = healTime > 0 ? healPerSecond * healTime : 0
        healTime = Swift.max(duration, 0.1)
        healPerSecond = (remaining + total) / healTime
    }

    mutating func applyDash(velocity: CGPoint, duration: CGFloat) {
        dashVelocity = velocity
        dashTime = duration
    }

    mutating func tick(_ dt: CGFloat) {
        slowTime = Swift.max(0, slowTime - dt)
        stunTime = Swift.max(0, stunTime - dt)
        speedBoostTime = Swift.max(0, speedBoostTime - dt)
        fireRateBoostTime = Swift.max(0, fireRateBoostTime - dt)
        healTime = Swift.max(0, healTime - dt)
        dashTime = Swift.max(0, dashTime - dt)
    }

    mutating func clear() {
        self = StatusEffects()
    }
}
