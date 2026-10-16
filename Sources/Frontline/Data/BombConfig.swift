import CoreGraphics

/// Bomb timings. Bomb mode (5 vs 5, one life): one carried bomb planted on A or B. Rush (16 vs 16):
/// two stations armed in place by any attacker. Either way it blows 45 s after arming unless defused.
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
    /// Rush: how close an attacker must stand to a station to arm it, and the attackers' respawn tickets.
    static let armRadius: CGFloat = 70
    static let rushTickets = 120
    static let rushRespawnDelay: CGFloat = 8
}
