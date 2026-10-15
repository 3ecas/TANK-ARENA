import CoreGraphics

/// All 15 purchasable abilities (the roll on F is built in). Values are per rank (1...3).
enum AbilityCatalog {
    static let all: [AbilityDef] = combat + support + callIns + summons

    private static let table: [AbilityID: AbilityDef] = {
        var result: [AbilityID: AbilityDef] = [:]
        for def in all { result[def.id] = def }
        return result
    }()

    static func def(_ id: AbilityID) -> AbilityDef {
        guard let def = table[id] else { fatalError("Missing ability definition: \(id)") }
        return def
    }

    static func abilities(in category: AbilityCategory) -> [AbilityDef] {
        all.filter { $0.category == category }
    }

    static let combat: [AbilityDef] = [
        AbilityDef(id: .fragGrenade, name: "Frag Grenade", shortName: "FRAG", category: .combat,
                   castMode: .area, range: 520, radius: 120, cooldowns: [9, 8, 7], values: [120, 170, 230],
                   goldCost: 400, upgradeCost: 300, summary: "Throw a grenade that explodes on landing."),
        AbilityDef(id: .stim, name: "Combat Stim", shortName: "STIM", category: .combat,
                   castMode: .instant, cooldowns: [18, 16, 14], values: [0.4, 0.55, 0.7], durations: [5, 5.5, 6],
                   goldCost: 350, upgradeCost: 300,
                   summary: "Costs 30 HP. Boosts fire rate and move speed."),
        AbilityDef(id: .deployShield, name: "Deployable Shield", shortName: "SHLD", category: .combat,
                   castMode: .instant, radius: 110, cooldowns: [20, 18, 16], values: [400, 600, 800],
                   durations: [6, 7, 8], goldCost: 450, upgradeCost: 350,
                   summary: "Drop a dome that blocks enemy fire from outside."),
        AbilityDef(id: .smokeGrenade, name: "Smoke Grenade", shortName: "SMK", category: .combat,
                   castMode: .area, range: 560, radius: 170, cooldowns: [18, 16, 14], values: [0, 0, 0],
                   durations: [6, 7, 8], goldCost: 300, upgradeCost: 250,
                   summary: "Allies inside the smoke are hidden from enemies."),
    ]

    static let support: [AbilityDef] = [
        AbilityDef(id: .medkit, name: "Medkit", shortName: "MED", category: .support,
                   castMode: .instant, radius: 260, cooldowns: [16, 14, 12], values: [180, 260, 350],
                   durations: [4, 4, 4], goldCost: 350, upgradeCost: 300,
                   summary: "Heal over time. Nearby allies get half."),
        AbilityDef(id: .uavRecon, name: "UAV Recon", shortName: "UAV", category: .support,
                   castMode: .area, range: 1600, radius: 550, cooldowns: [30, 26, 22], values: [550, 650, 750],
                   durations: [8, 9, 10], goldCost: 300, upgradeCost: 250, isCallIn: true,
                   summary: "Reveal a large area of the fog of war."),
        AbilityDef(id: .supplyDrop, name: "Supply Drop", shortName: "SUP", category: .support,
                   castMode: .area, range: 620, radius: 130, cooldowns: [35, 30, 25], values: [250, 350, 450],
                   durations: [10, 10, 10], goldCost: 450, upgradeCost: 350, isCallIn: true,
                   summary: "Crate lands after 1.5s: heals allies and refills ammo."),
        AbilityDef(id: .sentryTurret, name: "Sentry Turret", shortName: "SNTY", category: .support,
                   castMode: .area, range: 320, radius: 40, cooldowns: [30, 26, 22], values: [1.0, 1.3, 1.6],
                   durations: [25, 30, 35], goldCost: 500, upgradeCost: 400,
                   summary: "Deploy an automated turret (max 2)."),
    ]

    static let callIns: [AbilityDef] = [
        AbilityDef(id: .strafingRun, name: "Strafing Run", shortName: "STRF", category: .callIn,
                   castMode: .line(length: 720), range: 900, radius: 50, cooldowns: [28, 24, 20],
                   values: [55, 75, 95], goldCost: 600, upgradeCost: 450, isCallIn: true,
                   summary: "A jet strafes a line after a short warning."),
        AbilityDef(id: .carpetBombing, name: "Carpet Bombing", shortName: "CRPT", category: .callIn,
                   tier: .ultimate, castMode: .area, range: 1400, radius: 380, cooldowns: [90, 75, 60],
                   values: [110, 150, 190], cpCost: 3, goldCost: 1200, upgradeCost: 800, isCallIn: true,
                   summary: "ULTIMATE. Bombers flatten a huge area."),
        AbilityDef(id: .artilleryBarrage, name: "Artillery Barrage", shortName: "ARTY", category: .callIn,
                   castMode: .area, range: 1100, radius: 220, cooldowns: [26, 22, 18], values: [90, 125, 160],
                   goldCost: 650, upgradeCost: 450, isCallIn: true,
                   summary: "Shells rain on a circle after a delay."),
        AbilityDef(id: .empStrike, name: "EMP Strike", shortName: "EMP", category: .callIn,
                   castMode: .area, range: 1000, radius: 260, cooldowns: [30, 26, 22], values: [60, 90, 120],
                   durations: [2, 2.5, 3], goldCost: 550, upgradeCost: 400, isCallIn: true,
                   summary: "Disables vehicles and turrets, slows infantry."),
    ]

    static let summons: [AbilityDef] = [
        AbilityDef(id: .callTank, name: "Call in Tank", shortName: "TANK", category: .summon,
                   tier: .ultimate, castMode: .area, range: 700, radius: 40, cooldowns: [70, 60, 50],
                   values: [1.0, 1.25, 1.5], durations: [40, 50, 60], cpCost: 2, goldCost: 1000,
                   upgradeCost: 700, isCallIn: true,
                   summary: "ULTIMATE. A tank pushes the nearest lane (max 1)."),
        AbilityDef(id: .reinforcements, name: "Reinforcements", shortName: "SQD", category: .summon,
                   castMode: .area, range: 500, radius: 90, cooldowns: [40, 35, 30], values: [4, 5, 6],
                   durations: [45, 50, 55], goldCost: 700, upgradeCost: 500, isCallIn: true,
                   summary: "A squad follows you, then joins a lane (max 2)."),
        AbilityDef(id: .attackHelicopter, name: "Attack Helicopter", shortName: "HELI", category: .summon,
                   tier: .ultimate, castMode: .instant, cooldowns: [100, 85, 70], values: [1.0, 1.25, 1.5],
                   durations: [20, 25, 30], cpCost: 3, goldCost: 1300, upgradeCost: 900, isCallIn: true,
                   summary: "ULTIMATE. A gunship escorts you for a while."),
    ]
}
