import CoreGraphics

/// Different AI builds so every enemy plays a little differently.
enum AIBuildConfig {
    static let assault = AIBuild(
        name: "Assault",
        startingAbilities: [.fragGrenade, .combatRoll, .stim, .strafingRun],
        ultimate: .carpetBombing,
        purchases: [.gear(.extendedMag), .gear(.combatBoots), .gear(.reflexScope), .ability(.fragGrenade),
                    .gear(.kevlarVest), .ability(.carpetBombing), .gear(.drumMag), .ability(.strafingRun),
                    .gear(.thermalScope), .gear(.sprintBoots), .gear(.ceramicPlates), .ability(.stim)])

    static let sniper = AIBuild(
        name: "Marksman",
        startingAbilities: [.smokeGrenade, .combatRoll, .artilleryBarrage, .uavRecon],
        ultimate: .carpetBombing,
        purchases: [.gear(.reflexScope), .weapon(.sniperRifle), .gear(.combatBoots), .ability(.artilleryBarrage),
                    .gear(.thermalScope), .ability(.carpetBombing), .gear(.medicPouch), .gear(.sprintBoots),
                    .ability(.combatRoll), .gear(.kevlarVest), .gear(.fieldRadio)])

    static let heavy = AIBuild(
        name: "Heavy",
        startingAbilities: [.deployShield, .fragGrenade, .reinforcements, .medkit],
        ultimate: .callTank,
        purchases: [.gear(.kevlarVest), .weapon(.lmg), .gear(.medicPouch), .ability(.callTank),
                    .gear(.ceramicPlates), .gear(.extendedMag), .ability(.reinforcements), .gear(.traumaKit),
                    .gear(.combatBoots), .gear(.drumMag)])

    static let support = AIBuild(
        name: "Support",
        startingAbilities: [.medkit, .supplyDrop, .sentryTurret, .empStrike],
        ultimate: .attackHelicopter,
        purchases: [.gear(.medicPouch), .gear(.fieldRadio), .gear(.combatBoots), .ability(.medkit),
                    .ability(.attackHelicopter), .gear(.kevlarVest), .gear(.commandUplink), .ability(.empStrike),
                    .gear(.traumaKit), .gear(.sprintBoots)])

    static let commando = AIBuild(
        name: "Commando",
        startingAbilities: [.combatRoll, .stim, .fragGrenade, .reinforcements],
        ultimate: .attackHelicopter,
        purchases: [.weapon(.shotgun), .gear(.combatBoots), .gear(.kevlarVest), .ability(.combatRoll),
                    .ability(.attackHelicopter), .gear(.sprintBoots), .gear(.reflexScope), .gear(.ceramicPlates),
                    .ability(.stim), .gear(.thermalScope)])
}
