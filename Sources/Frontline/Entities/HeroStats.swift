import CoreGraphics

/// Derived hero stats (level + weapon + gear). Computed by `StatCalculator`.
struct HeroStats {
    var maxHp: CGFloat = HeroConfig.baseHp
    var armor: CGFloat = HeroConfig.baseArmor
    var speed: CGFloat = HeroConfig.baseSpeed
    var damage: CGFloat = 17
    var range: CGFloat = 380
    var fireInterval: CGFloat = 0.4
    var magSize: Int = 12
    var reloadTime: CGFloat = 1.3
    var pellets: Int = 1
    var spread: CGFloat = 0.04
    var hpRegen: CGFloat = HeroConfig.baseRegen
    var cooldownReduction: CGFloat = 0
    var abilityPower: CGFloat = 1
}
