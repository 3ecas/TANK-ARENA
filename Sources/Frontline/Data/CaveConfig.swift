import CoreGraphics

/// Tuning for the procedurally generated cave map.
enum CaveConfig {
    /// Rock is built on a grid of square cells this size.
    static let cellSize: CGFloat = 40
    /// Noise above this value is rock (lower = more solid rock, fewer open chambers).
    static let rockThreshold: CGFloat = 0.33
    /// Noise feature sizes, in cells (large caverns + small detail).
    static let noiseScaleLarge: CGFloat = 7
    static let noiseScaleSmall: CGFloat = 3.2
    static let noiseWeightLarge: CGFloat = 0.65

    /// Main tunnels: y positions of the outer routes (the middle route runs through the zones).
    static let laneYs: [CGFloat] = [300, 1500]
    static let routeRadius: ClosedRange<CGFloat> = 44...58
    static let middleRadius: ClosedRange<CGFloat> = 46...60
    static let laneJitter: CGFloat = 140
    static let laneStep: ClosedRange<CGFloat> = 180...240

    /// Small side passages linking neighbouring tunnels.
    static let connectorsPerGap: ClosedRange<Int> = 5...7
    static let connectorRadius: ClosedRange<CGFloat> = 34...40
    static let connectorWiggle: CGFloat = 120

    /// Open area around each zone, and rock pillars inside it for cover.
    static let zoneClearing: CGFloat = 190
    static let zonePillars = 3
    static let pillarDistance: ClosedRange<CGFloat> = 50...90

    /// Cave spawns: middle of the left and right edges.
    static let blueSpawn = CGRect(x: 40, y: 640, width: 220, height: 520)
    static let redSpawn = CGRect(x: 2540, y: 640, width: 220, height: 520)

    static let zones: [ZoneConfig.ZoneSpec] = [
        ZoneConfig.ZoneSpec(name: "A", center: CGPoint(x: 650, y: 900)),
        ZoneConfig.ZoneSpec(name: "B", center: CGPoint(x: 1400, y: 900)),
        ZoneConfig.ZoneSpec(name: "C", center: CGPoint(x: 2150, y: 900)),
    ]
    /// Seeds tried before falling back to the city map (a seed is rejected if a zone or spawn is unreachable).
    static let maxAttempts = 12
}
