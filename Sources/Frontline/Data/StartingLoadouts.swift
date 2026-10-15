import Foundation

/// Starting ability loadouts the player can pick in the main menu.
struct StartingLoadout {
    var name: String
    var summary: String
    var abilities: [AbilityID]
}

enum StartingLoadouts {
    static let all: [StartingLoadout] = [
        StartingLoadout(name: "Assault", summary: "Grenade · Roll · Medkit · Strafing Run",
                        abilities: [.fragGrenade, .combatRoll, .medkit, .strafingRun]),
        StartingLoadout(name: "Support", summary: "Medkit · Smoke · Supply Drop · Sentry",
                        abilities: [.medkit, .smokeGrenade, .supplyDrop, .sentryTurret]),
        StartingLoadout(name: "Commander", summary: "Grenade · Roll · Artillery · Squad",
                        abilities: [.fragGrenade, .combatRoll, .artilleryBarrage, .reinforcements]),
    ]
}
