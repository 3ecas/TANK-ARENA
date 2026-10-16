import CoreGraphics

/// Bomb round (5 vs 5): attackers carry one bomb and plant it on site A or B; it blows after 45 s
/// unless a defender defuses it. One life per round.
enum BombConfig {
    /// Round length before the bomb is planted. If time runs out with no bomb planted, defenders win.
    static let roundTime: CGFloat = 120
    /// Seconds from plant to explosion.
    static let fuseTime: CGFloat = 45
    /// Seconds of holding E inside a site to plant, and next to the bomb to defuse.
    static let plantTime: CGFloat = 3
    static let defuseTime: CGFloat = 5
    /// How close a defender must stand to the bomb to defuse it.
    static let defuseRadius: CGFloat = 60
    /// How close an attacker must walk to a dropped bomb to pick it up.
    static let pickupRadius: CGFloat = 30
    /// Explosion: kills inside `killRadius`, damage falls off to zero at `blastRadius`.
    static let killRadius: CGFloat = 260
    static let blastRadius: CGFloat = 560
    static let blastDamage: CGFloat = 400
}
