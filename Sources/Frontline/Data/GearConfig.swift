import CoreGraphics

enum GearID: String, CaseIterable {
    case kevlarVest, ceramicPlates
    case combatBoots, sprintBoots
    case extendedMag, drumMag
    case reflexScope, thermalScope
    case medicPouch, traumaKit
    case fieldRadio, commandUplink
}

/// Additive bonuses granted by gear.
struct StatBonuses {
    var maxHp: CGFloat = 0
    var armor: CGFloat = 0
    var speed: CGFloat = 0
    var damagePct: CGFloat = 0
    var fireRatePct: CGFloat = 0
    var magPct: CGFloat = 0
    var rangePct: CGFloat = 0
    var hpRegen: CGFloat = 0
    var cooldownReduction: CGFloat = 0
    var abilityPower: CGFloat = 0

    static func + (a: StatBonuses, b: StatBonuses) -> StatBonuses {
        StatBonuses(maxHp: a.maxHp + b.maxHp, armor: a.armor + b.armor, speed: a.speed + b.speed,
                    damagePct: a.damagePct + b.damagePct, fireRatePct: a.fireRatePct + b.fireRatePct,
                    magPct: a.magPct + b.magPct, rangePct: a.rangePct + b.rangePct,
                    hpRegen: a.hpRegen + b.hpRegen,
                    cooldownReduction: a.cooldownReduction + b.cooldownReduction,
                    abilityPower: a.abilityPower + b.abilityPower)
    }
}

struct GearDef {
    var id: GearID
    var name: String
    /// Gold cost. For advanced items this is the upgrade cost (the basic item is consumed).
    var cost: Int
    var requires: GearID?
    var bonuses: StatBonuses
    var summary: String
}

enum GearCatalog {
    static let all: [GearDef] = [
        GearDef(id: .kevlarVest, name: "Kevlar Vest", cost: 450, requires: nil,
                bonuses: StatBonuses(maxHp: 150, armor: 12), summary: "+150 HP, +12 armor"),
        GearDef(id: .ceramicPlates, name: "Ceramic Plates", cost: 900, requires: .kevlarVest,
                bonuses: StatBonuses(maxHp: 400, armor: 35), summary: "+400 HP, +35 armor"),
        GearDef(id: .combatBoots, name: "Combat Boots", cost: 350, requires: nil,
                bonuses: StatBonuses(speed: 25), summary: "+25 move speed"),
        GearDef(id: .sprintBoots, name: "Sprint Boots", cost: 650, requires: .combatBoots,
                bonuses: StatBonuses(armor: 5, speed: 55), summary: "+55 move speed, +5 armor"),
        GearDef(id: .extendedMag, name: "Extended Mag", cost: 400, requires: nil,
                bonuses: StatBonuses(fireRatePct: 0.05, magPct: 0.4), summary: "+40% magazine, +5% fire rate"),
        GearDef(id: .drumMag, name: "Drum Magazine", cost: 800, requires: .extendedMag,
                bonuses: StatBonuses(fireRatePct: 0.15, magPct: 1.0), summary: "+100% magazine, +15% fire rate"),
        GearDef(id: .reflexScope, name: "Reflex Scope", cost: 500, requires: nil,
                bonuses: StatBonuses(damagePct: 0.10, rangePct: 0.08), summary: "+10% damage, +8% range"),
        GearDef(id: .thermalScope, name: "Thermal Scope", cost: 1000, requires: .reflexScope,
                bonuses: StatBonuses(damagePct: 0.25, rangePct: 0.15), summary: "+25% damage, +15% range"),
        GearDef(id: .medicPouch, name: "Medic Pouch", cost: 350, requires: nil,
                bonuses: StatBonuses(maxHp: 80, hpRegen: 4), summary: "+80 HP, +4 HP/s regen"),
        GearDef(id: .traumaKit, name: "Field Trauma Kit", cost: 800, requires: .medicPouch,
                bonuses: StatBonuses(maxHp: 200, hpRegen: 10), summary: "+200 HP, +10 HP/s regen"),
        GearDef(id: .fieldRadio, name: "Field Radio", cost: 500, requires: nil,
                bonuses: StatBonuses(cooldownReduction: 0.10, abilityPower: 0.10),
                summary: "-10% cooldowns, +10% ability power"),
        GearDef(id: .commandUplink, name: "Command Uplink", cost: 950, requires: .fieldRadio,
                bonuses: StatBonuses(cooldownReduction: 0.25, abilityPower: 0.25),
                summary: "-25% cooldowns, +25% ability power"),
    ]

    static func def(_ id: GearID) -> GearDef {
        all.first { $0.id == id } ?? all[0]
    }
}
