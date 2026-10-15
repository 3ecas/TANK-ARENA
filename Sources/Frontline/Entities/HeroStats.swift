import CoreGraphics

/// Derived hero stats (level + weapon + gear). Computed by `StatCalculator`.
struct HeroStats {
    var maxHp: CGFloat = HeroConfig.baseHp
    var armor: CGFloat = HeroConfig.baseArmor
    var speed: CGFloat = HeroConfig.baseSpeed
    var damage: CGFloat = 19
    var range: CGFloat = 420
    var fireInterval: CGFloat = 0.15
    var magSize: Int = 30
    var reloadTime: CGFloat = 1.8
    var pellets: Int = 1
    var spread: CGFloat = 0.04
    var hpRegen: CGFloat = HeroConfig.baseRegen
    var cooldownReduction: CGFloat = 0
    var abilityPower: CGFloat = 1
}
