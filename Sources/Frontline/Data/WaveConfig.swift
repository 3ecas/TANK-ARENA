import CoreGraphics

enum WaveConfig {
    static let firstWaveTime: CGFloat = 8
    static let interval: CGFloat = 30
    /// Seconds between units of a wave leaving the base.
    static let spawnStagger: CGFloat = 0.55
    static let riflemen = 3
    static let rocketSoldiers = 2
    /// From this game time, every `tankEvery` waves includes a tank.
    static let tankStartTime: CGFloat = 360
    static let tankEvery = 3
    /// From this game time, every `apcEvery` waves includes an APC.
    static let apcStartTime: CGFloat = 540
    static let apcEvery = 2
    /// Extra rifleman after this time.
    static let lateGameTime: CGFloat = 900
    /// Troop HP/damage grows by this fraction every 5 minutes.
    static let scalingPerFiveMinutes: CGFloat = 0.08
    /// Riflemen deployed when an APC is destroyed.
    static let apcDeployCount = 2
    /// Troop aggro range while walking a lane.
    static let troopAggroRange: CGFloat = 380
}
