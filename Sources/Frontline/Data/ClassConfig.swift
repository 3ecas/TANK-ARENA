import CoreGraphics

/// Soldier classes. Everyone has a primary, a pistol and a knife; the class changes the rest.
enum SoldierClass: CaseIterable {
    /// More ammo, faster, one extra grenade; Q: adrenaline (a short sprint).
    case assault
    /// Q: drops a health box; holds E on a downed teammate to revive them.
    case medic
    /// Carries an RPG (slot 3) against vehicles; Q: drops an ammo box.
    case engineer

    var displayName: String {
        switch self {
        case .assault: return "Assault"
        case .medic: return "Medic"
        case .engineer: return "Engineer"
        }
    }

    var ammoMultiplier: CGFloat { self == .assault ? 1.5 : 1 }
    var speedMultiplier: CGFloat { self == .assault ? 1.1 : 1 }
    var grenades: Int { self == .assault ? 2 : 1 }
    var abilityName: String {
        switch self {
        case .assault: return "Adrenaline"
        case .medic: return "Health box"
        case .engineer: return "Ammo box"
        }
    }
}

enum ClassConfig {
    /// Seconds between class abilities (Q).
    static let abilityCooldown: CGFloat = 18
    /// Adrenaline: speed boost and its length.
    static let sprintMultiplier: CGFloat = 1.45
    static let sprintTime: CGFloat = 4
    /// Supply boxes: lifetime, reach, healing per second, and how often ammo is topped up.
    static let boxLifetime: CGFloat = 25
    static let boxRadius: CGFloat = 90
    static let healPerSecond: CGFloat = 14
    static let ammoInterval: CGFloat = 1.5
    /// Rush: a soldier who drops can be revived for this long before they are out (and respawn).
    static let downedTime: CGFloat = 10
    static let reviveTime: CGFloat = 1.6
    static let reviveRadius: CGFloat = 55
    static let reviveHealth: CGFloat = 50
}
