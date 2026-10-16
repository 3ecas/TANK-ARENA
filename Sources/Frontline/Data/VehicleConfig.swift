import CoreGraphics

enum VehicleKind {
    case tank, helicopter

    var displayName: String {
        switch self {
        case .tank: return "Tank"
        case .helicopter: return "Helicopter"
        }
    }
}

/// Vehicles are killstreak rewards in the open rush sectors (3–5). The soldier who calls one in drives it.
enum VehicleConfig {
    /// Kills in a row (without dying) that earn each vehicle.
    static let tankStreak = 3
    static let helicopterStreak = 5
    /// At most this many of each per team at a time.
    static let tanksPerTeam = 2
    static let helicoptersPerTeam = 1

    // Tank: slow, tough, turret cannon with an explosive shell.
    static let tankHP: CGFloat = 1400
    static let tankRadius: CGFloat = 34
    static let tankSpeed: CGFloat = 95
    static let tankTurnRate: CGFloat = 2.2
    static let turretTurnRate: CGFloat = 3.0
    static let shellReload: CGFloat = 2.4
    static let shellRange: CGFloat = 1000
    static let shellBlast: CGFloat = 110
    static let shellDamage: CGFloat = 120
    static let shellVehicleDamage: CGFloat = 320

    // Helicopter: fast, flies over walls, minigun; leaves after `helicopterTime` seconds.
    static let helicopterHP: CGFloat = 800
    static let helicopterRadius: CGFloat = 30
    static let helicopterSpeed: CGFloat = 230
    static let helicopterTime: CGFloat = 60
    static let minigunInterval: CGFloat = 0.08
    static let minigunDamage: CGFloat = 13
    static let minigunVehicleDamage: CGFloat = 6
    static let minigunSpread: CGFloat = 0.05
    static let minigunRange: CGFloat = 800

    /// Bullets do this fraction of their damage to vehicles (rockets and shells do full vehicle damage).
    static let bulletVehicleFactor: CGFloat = 0.08
    /// Explosion when a vehicle is destroyed.
    static let wreckBlast: CGFloat = 140
    static let wreckDamage: CGFloat = 90
}
