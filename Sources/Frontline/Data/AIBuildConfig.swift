import CoreGraphics

/// Different AI builds so every enemy plays a little differently. Everyone starts with a pistol
/// and no abilities; abilities, weapons and gear are bought in this order.
enum AIBuildConfig {
    static let assault = AIBuild(
        name: "Assault",
        abilities: [.fragGrenade, .stim, .strafingRun, .carpetBombing],
        purchases: [.ability(.fragGrenade), .weapon(.assaultRifle), .ability(.stim), .gear(.extendedMag),
                    .ability(.strafingRun), .gear(.combatBoots), .gear(.reflexScope), .ability(.carpetBombing),
                    .ability(.fragGrenade), .gear(.kevlarVest), .gear(.drumMag), .ability(.strafingRun),
                    .gear(.thermalScope), .gear(.sprintBoots), .gear(.ceramicPlates), .ability(.stim)])

    static let sniper = AIBuild(
        name: "Marksman",
        abilities: [.smokeGrenade, .artilleryBarrage, .uavRecon, .carpetBombing],
        purchases: [.ability(.smokeGrenade), .gear(.reflexScope), .ability(.artilleryBarrage), .weapon(.sniperRifle),
                    .ability(.uavRecon), .gear(.combatBoots), .gear(.thermalScope), .ability(.carpetBombing),
                    .ability(.artilleryBarrage), .gear(.medicPouch), .gear(.sprintBoots), .gear(.kevlarVest),
                    .gear(.fieldRadio)])

    static let heavy = AIBuild(
        name: "Heavy",
        abilities: [.deployShield, .fragGrenade, .reinforcements, .callTank],
        purchases: [.ability(.deployShield), .gear(.kevlarVest), .ability(.fragGrenade), .weapon(.lmg),
                    .ability(.reinforcements), .gear(.medicPouch), .ability(.callTank), .gear(.ceramicPlates),
                    .gear(.extendedMag), .ability(.reinforcements), .gear(.traumaKit), .gear(.combatBoots),
                    .gear(.drumMag)])

    static let support = AIBuild(
        name: "Support",
        abilities: [.medkit, .supplyDrop, .empStrike, .attackHelicopter],
        purchases: [.ability(.medkit), .gear(.medicPouch), .ability(.supplyDrop), .weapon(.assaultRifle),
                    .ability(.empStrike), .gear(.fieldRadio), .gear(.combatBoots), .ability(.attackHelicopter),
                    .ability(.medkit), .gear(.kevlarVest), .gear(.commandUplink), .gear(.traumaKit),
                    .gear(.sprintBoots)])

    static let commando = AIBuild(
        name: "Commando",
        abilities: [.stim, .fragGrenade, .sentryTurret, .attackHelicopter],
        purchases: [.ability(.stim), .gear(.combatBoots), .ability(.fragGrenade), .weapon(.shotgun),
                    .ability(.sentryTurret), .gear(.kevlarVest), .ability(.attackHelicopter), .gear(.sprintBoots),
                    .gear(.reflexScope), .ability(.stim), .gear(.ceramicPlates), .gear(.thermalScope)])
}
