import CoreGraphics

enum WeaponID: CaseIterable {
    case assaultRifle, smg, shotgun, pistol
}

struct WeaponDef {
    var id: WeaponID
    var name: String
    /// Damage per pellet.
    var damage: CGFloat
    /// Seconds between shots.
    var interval: CGFloat
    var magSize: Int
    /// Spare rounds outside the magazine (nil = unlimited).
    var reserveAmmo: Int?
    var reloadTime: CGFloat
    /// Half-angle of the random spread cone (radians).
    var spread: CGFloat
    var pellets: Int
    var range: CGFloat
    /// Automatic weapons fire while the trigger is held; others fire once per click.
    var isAutomatic: Bool
    var speedMultiplier: CGFloat
}

enum WeaponCatalog {
    static let assaultRifle = WeaponDef(id: .assaultRifle, name: "Assault Rifle", damage: 26, interval: 0.11,
                                        magSize: 30, reserveAmmo: 90, reloadTime: 2.3, spread: 0.035, pellets: 1,
                                        range: 1000, isAutomatic: true, speedMultiplier: 0.95)
    static let smg = WeaponDef(id: .smg, name: "SMG", damage: 19, interval: 0.075, magSize: 30, reserveAmmo: 120,
                               reloadTime: 2.0, spread: 0.06, pellets: 1, range: 700, isAutomatic: true,
                               speedMultiplier: 1.0)
    static let shotgun = WeaponDef(id: .shotgun, name: "Shotgun", damage: 14, interval: 0.85, magSize: 8,
                                   reserveAmmo: 32, reloadTime: 2.6, spread: 0.16, pellets: 8, range: 430,
                                   isAutomatic: false, speedMultiplier: 0.97)
    static let pistol = WeaponDef(id: .pistol, name: "Pistol", damage: 22, interval: 0.22, magSize: 12,
                                  reserveAmmo: nil, reloadTime: 1.4, spread: 0.025, pellets: 1, range: 800,
                                  isAutomatic: false, speedMultiplier: 1.05)

    static func def(_ id: WeaponID) -> WeaponDef {
        switch id {
        case .assaultRifle: return assaultRifle
        case .smg: return smg
        case .shotgun: return shotgun
        case .pistol: return pistol
        }
    }

    /// Primary weapons are handed out with these weights.
    static let primaryWeights: [(WeaponID, CGFloat)] = [(.assaultRifle, 0.45), (.smg, 0.35), (.shotgun, 0.2)]

    static func randomPrimary() -> WeaponID {
        var roll = CGFloat.random(in: 0..<1)
        for (id, weight) in primaryWeights {
            if roll < weight { return id }
            roll -= weight
        }
        return .assaultRifle
    }
}
