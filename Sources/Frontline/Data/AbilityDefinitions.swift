import CoreGraphics

enum AbilityID: String, CaseIterable {
    case fragGrenade, combatRoll, stim, deployShield, smokeGrenade
    case medkit, uavRecon, supplyDrop, sentryTurret
    case strafingRun, carpetBombing, artilleryBarrage, empStrike
    case callTank, reinforcements, attackHelicopter
}

enum AbilityCategory: Int, CaseIterable {
    case combat, support, callIn, summon

    var displayName: String {
        switch self {
        case .combat: return "Combat"
        case .support: return "Support"
        case .callIn: return "Call-ins"
        case .summon: return "Summons"
        }
    }
}

enum AbilityTier {
    case basic, ultimate
}

enum CastMode {
    /// Fires immediately toward the cursor.
    case instant
    /// Held to aim a circle (radius = def.radius), cast on release.
    case area
    /// Held to aim a line of the given length (width = def.radius * 2), cast on release.
    case line(length: CGFloat)

    var isInstant: Bool {
        if case .instant = self { return true }
        return false
    }
}

struct AbilityDef {
    var id: AbilityID
    var name: String
    var shortName: String
    var category: AbilityCategory
    var tier: AbilityTier = .basic
    var castMode: CastMode
    var range: CGFloat = 0
    var radius: CGFloat = 0
    var cooldowns: [CGFloat]
    var values: [CGFloat]
    var durations: [CGFloat] = [0]
    var cpCost: Int = 0
    var goldCost: Int
    var upgradeCost: Int
    var isCallIn: Bool = false
    var summary: String

    static let maxRank = 3

    func cooldown(at rank: Int) -> CGFloat { Self.pick(cooldowns, rank) }
    func value(at rank: Int) -> CGFloat { Self.pick(values, rank) }
    func duration(at rank: Int) -> CGFloat { Self.pick(durations, rank) }

    private static func pick(_ list: [CGFloat], _ rank: Int) -> CGFloat {
        guard !list.isEmpty else { return 0 }
        let index = Swift.min(Swift.max(rank, 1), list.count) - 1
        return list[index]
    }
}
