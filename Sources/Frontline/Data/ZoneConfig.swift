import CoreGraphics

/// Control zones and match timing.
enum ZoneConfig {
    struct ZoneSpec {
        let name: String
        let center: CGPoint
    }

    /// City zones: A near the blue spawn, B contested in the middle, C near the red spawn.
    /// Scattered on purpose, not in a line.
    static let zones: [ZoneSpec] = [
        ZoneSpec(name: "A", center: CGPoint(x: 700, y: 640)),
        ZoneSpec(name: "B", center: CGPoint(x: 1460, y: 1140)),
        ZoneSpec(name: "C", center: CGPoint(x: 2230, y: 860)),
    ]
    static let radius: CGFloat = 140
    /// Seconds for a lone team to capture a neutral zone (twice that to flip an enemy zone).
    static let captureTime: CGFloat = 3
    /// Points per second for each zone a team controls.
    static let pointsPerSecond: CGFloat = 1
    /// Regular match length in seconds; then the team with more points wins (a tie means sudden death).
    static let matchDuration: CGFloat = 300
}
