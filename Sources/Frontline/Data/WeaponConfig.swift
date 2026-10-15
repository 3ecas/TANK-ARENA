import CoreGraphics

enum WeaponID: String, CaseIterable {
    case assaultRifle, shotgun, sniperRifle, lmg
}

struct WeaponDef {
    var id: WeaponID
    var name: String
    var cost: Int
    /// Damage per pellet.
    var damage: CGFloat
    var range: CGFloat
    var interval: CGFloat
    var magSize: Int
    var reloadTime: CGFloat
    var pellets: Int
    var spread: CGFloat
    var speedMultiplier: CGFloat
    var summary: String

    var totalDamage: CGFloat { damage * CGFloat(pellets) }
}

enum WeaponCatalog {
    static let all: [WeaponDef] = [
        WeaponDef(id: .assaultRifle, name: "Assault Rifle", cost: 0, damage: 19, range: 420, interval: 0.15,
                  magSize: 30, reloadTime: 1.8, pellets: 1, spread: 0.04, speedMultiplier: 1.0,
                  summary: "Reliable all-rounder. Medium range, steady fire."),
        WeaponDef(id: .shotgun, name: "Combat Shotgun", cost: 600, damage: 16, range: 270, interval: 0.85,
                  magSize: 7, reloadTime: 2.4, pellets: 7, spread: 0.25, speedMultiplier: 1.05,
                  summary: "Huge burst damage up close. Short range, light."),
        WeaponDef(id: .sniperRifle, name: "Sniper Rifle", cost: 900, damage: 120, range: 680, interval: 1.35,
                  magSize: 5, reloadTime: 2.6, pellets: 1, spread: 0, speedMultiplier: 0.95,
                  summary: "Long range precision. Slow, heavy hits."),
        WeaponDef(id: .lmg, name: "Light Machine Gun", cost: 1100, damage: 15, range: 460, interval: 0.095,
                  magSize: 90, reloadTime: 3.6, pellets: 1, spread: 0.08, speedMultiplier: 0.88,
                  summary: "Sustained suppressing fire. Huge magazine, slows you."),
    ]

    static func def(_ id: WeaponID) -> WeaponDef {
        all.first { $0.id == id } ?? all[0]
    }
}
