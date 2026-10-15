import CoreGraphics

/// A single purchase step in an AI build order.
enum BuildStep {
    case ability(AbilityID)
    case weapon(WeaponID)
    case gear(GearID)
}

/// AI hero build: preferred abilities (first four are the starting loadout) and a purchase order.
struct AIBuild {
    var name: String
    var startingAbilities: [AbilityID]
    var ultimate: AbilityID
    var purchases: [BuildStep]
}

/// How an AI hero spends its time.
enum AIRole {
    case laner, roamer
}

struct RosterEntry {
    var name: String
    var lane: Lane
    var role: AIRole
    var build: AIBuild
}

enum RosterConfig {
    static let playerName = "You"

    static let blueAllies: [RosterEntry] = [
        RosterEntry(name: "Hawk", lane: .top, role: .laner, build: AIBuildConfig.heavy),
        RosterEntry(name: "Rook", lane: .bot, role: .laner, build: AIBuildConfig.assault),
        RosterEntry(name: "Echo", lane: .bot, role: .laner, build: AIBuildConfig.support),
        RosterEntry(name: "Bishop", lane: .mid, role: .roamer, build: AIBuildConfig.commando),
    ]

    static let redEnemies: [RosterEntry] = [
        RosterEntry(name: "Viper", lane: .top, role: .laner, build: AIBuildConfig.assault),
        RosterEntry(name: "Ghost", lane: .mid, role: .laner, build: AIBuildConfig.sniper),
        RosterEntry(name: "Raven", lane: .bot, role: .laner, build: AIBuildConfig.heavy),
        RosterEntry(name: "Saber", lane: .bot, role: .laner, build: AIBuildConfig.support),
        RosterEntry(name: "Wolf", lane: .top, role: .roamer, build: AIBuildConfig.commando),
    ]
}
