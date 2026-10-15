import CoreGraphics

/// Control zones and match timing.
enum ZoneConfig {
    struct ZoneSpec {
        let name: String
        let center: CGPoint
    }

    /// A near the blue spawn, B contested in the middle, C near the red spawn
    /// (placed slightly differently on each side).
    static let zones: [ZoneSpec] = [
        ZoneSpec(name: "A", center: CGPoint(x: 700, y: 930)),
        ZoneSpec(name: "B", center: CGPoint(x: 1400, y: 900)),
        ZoneSpec(name: "C", center: CGPoint(x: 2150, y: 880)),
    ]
    static let radius: CGFloat = 140
    /// Seconds for a lone team to capture a neutral zone (twice that to flip an enemy zone).
    static let captureTime: CGFloat = 3
    /// Points per second for each zone a team controls.
    static let pointsPerSecond: CGFloat = 1
    /// Regular match length in seconds; then the team with more points wins (a tie means sudden death).
    static let matchDuration: CGFloat = 300
}
