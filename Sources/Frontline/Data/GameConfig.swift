import CoreGraphics

/// General rules of the 25 vs 25 battle.
enum GameConfig {
    /// Square game window: preferred and minimum side in points.
    static let windowSide: CGFloat = 1000
    static let minWindowSide: CGFloat = 860
    /// World area shown on screen (points). The scene is scaled to fit the window, so this never changes.
    static let viewSize = CGSize(width: 1000, height: 1000)
    static let teamSize = 25
    static let maxHp: CGFloat = 100
    /// Each soldier can come back once after dying.
    static let respawnsPerSoldier = 1
    static let respawnDelay: CGFloat = 5
    static let spawnProtection: CGFloat = 2
    static let soldierRadius: CGFloat = 12
    /// Walking speed (points per second) before weapon weight.
    static let walkSpeed: CGFloat = 118
    /// How far a soldier can see (line of sight is still required).
    /// How far anyone can see (the fog closes in beyond this; well inside the square window).
    static let visionRange: CGFloat = 640
    /// Angular width of the max-range marker on the player's aim line.
    static let rangeMarkerSpan: CGFloat = 0.22
    /// Field of view (full angle, radians): the player sees ~110 degrees in front, bots a bit wider.
    /// View cone (radians) — identical for the player and every bot.
    static let fieldOfView: CGFloat = 2.1
    /// How quickly the camera catches up with the player (higher = tighter).
    static let cameraFollowRate: CGFloat = 12
    /// The camera moves this fraction of the way toward the mouse...
    static let cameraLookAheadFraction: CGFloat = 0.5
    /// ...but never further than this from the player (keeps the player and their view range on screen).
    static let cameraLookAhead: CGFloat = 280
    /// Everyone notices enemies this close, even behind them.
    static let peripheralRadius: CGFloat = 70
    /// Fog of war drawing: darkness outside the view cone, rays cast per frame, texture resolution.
    static let fogAlpha: CGFloat = 0.55
    static let fogRayCount = 200
    /// Rays per teammate cone (shared vision), cheaper than the viewer's own.
    static let fogAllyRayCount = 72
    static let fogResolution: CGFloat = 0.25
    /// Shots are less accurate while moving.
    static let movingSpreadMultiplier: CGFloat = 1.8
    static let weaponSwitchTime: CGFloat = 0.35

    // Knife (F)
    static let knifeRange: CGFloat = 50
    static let knifeArc: CGFloat = 1.5
    static let knifeDamage: CGFloat = 55
    static let backstabDamage: CGFloat = 100
    static let knifeCooldown: CGFloat = 0.7

    // Navigation
    static let navCellSize: CGFloat = 20
    static let navPadding: CGFloat = 10
}
