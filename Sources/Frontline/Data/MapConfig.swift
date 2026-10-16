import CoreGraphics

/// "Compound": a closed indoor map (2400 x 1600) of rooms, corridors and doorways for 5 vs 5 bomb rounds.
/// Attackers start in the west room; defenders in the east room between the two bomb sites.
/// Routes: long corridor (north) to A, mid hall with short connectors to A and B, tunnels (south) to B.
/// (Designed on a 40-point grid, checked so every floor cell is reachable, then merged into rectangles.)
enum MapConfig {
    static let size = CGSize(width: 2400, height: 1600)
    static let attackerSpawn = CGRect(x: 40, y: 600, width: 320, height: 400)
    static let defenderSpawn = CGRect(x: 2040, y: 640, width: 280, height: 320)
    static let sites: [ZoneConfig.ZoneSpec] = [
        ZoneConfig.ZoneSpec(name: "A", center: CGPoint(x: 1820, y: 1300)),
        ZoneConfig.ZoneSpec(name: "B", center: CGPoint(x: 1820, y: 300)),
    ]

    /// Solid walls (merged from the grid).
    static let walls: [CGRect] = [
        CGRect(x: 0, y: 0, width: 2400, height: 80),
        CGRect(x: 0, y: 80, width: 1360, height: 40),
        CGRect(x: 1040, y: 160, width: 80, height: 80),
        CGRect(x: 2080, y: 160, width: 80, height: 80),
        CGRect(x: 280, y: 280, width: 440, height: 40),
        CGRect(x: 800, y: 280, width: 560, height: 40),
        CGRect(x: 1600, y: 280, width: 80, height: 80),
        CGRect(x: 1440, y: 400, width: 80, height: 40),
        CGRect(x: 720, y: 440, width: 80, height: 40),
        CGRect(x: 1880, y: 360, width: 80, height: 120),
        CGRect(x: 280, y: 320, width: 280, height: 200),
        CGRect(x: 1000, y: 320, width: 360, height: 200),
        CGRect(x: 0, y: 120, width: 120, height: 440),
        CGRect(x: 280, y: 520, width: 360, height: 40),
        CGRect(x: 720, y: 520, width: 640, height: 40),
        CGRect(x: 2240, y: 80, width: 160, height: 480),
        CGRect(x: 2120, y: 560, width: 280, height: 40),
        CGRect(x: 400, y: 560, width: 240, height: 120),
        CGRect(x: 720, y: 560, width: 800, height: 120),
        CGRect(x: 1680, y: 560, width: 320, height: 120),
        CGRect(x: 400, y: 680, width: 80, height: 80),
        CGRect(x: 1360, y: 680, width: 80, height: 80),
        CGRect(x: 1880, y: 680, width: 120, height: 80),
        CGRect(x: 800, y: 720, width: 80, height: 80),
        CGRect(x: 1120, y: 800, width: 80, height: 80),
        CGRect(x: 400, y: 840, width: 80, height: 80),
        CGRect(x: 1880, y: 840, width: 120, height: 80),
        CGRect(x: 2360, y: 600, width: 40, height: 400),
        CGRect(x: 0, y: 560, width: 40, height: 480),
        CGRect(x: 400, y: 920, width: 480, height: 120),
        CGRect(x: 960, y: 920, width: 560, height: 120),
        CGRect(x: 1680, y: 920, width: 320, height: 120),
        CGRect(x: 2120, y: 1000, width: 280, height: 40),
        CGRect(x: 1440, y: 1160, width: 80, height: 40),
        CGRect(x: 280, y: 1040, width: 280, height: 200),
        CGRect(x: 1080, y: 1040, width: 280, height: 200),
        CGRect(x: 1880, y: 1120, width: 80, height: 120),
        CGRect(x: 280, y: 1240, width: 440, height: 80),
        CGRect(x: 800, y: 1240, width: 560, height: 80),
        CGRect(x: 1600, y: 1280, width: 80, height: 80),
        CGRect(x: 400, y: 1360, width: 80, height: 80),
        CGRect(x: 2080, y: 1360, width: 80, height: 80),
        CGRect(x: 0, y: 1040, width: 120, height: 440),
        CGRect(x: 0, y: 1480, width: 1360, height: 40),
        CGRect(x: 2240, y: 1040, width: 160, height: 480),
        CGRect(x: 0, y: 1520, width: 2400, height: 80),
    ]

    /// Crates (cover inside rooms and corridors).
    static let crates: [CGRect] = [
        CGRect(x: 483, y: 1403, width: 34, height: 34),
        CGRect(x: 1763, y: 1403, width: 34, height: 34),
        CGRect(x: 1803, y: 1403, width: 34, height: 34),
        CGRect(x: 2003, y: 1243, width: 34, height: 34),
        CGRect(x: 963, y: 1163, width: 34, height: 34),
        CGRect(x: 1523, y: 1123, width: 34, height: 34),
        CGRect(x: 1723, y: 1123, width: 34, height: 34),
        CGRect(x: 2163, y: 1123, width: 34, height: 34),
        CGRect(x: 603, y: 1083, width: 34, height: 34),
        CGRect(x: 283, y: 923, width: 34, height: 34),
        CGRect(x: 2243, y: 923, width: 34, height: 34),
        CGRect(x: 1243, y: 883, width: 34, height: 34),
        CGRect(x: 603, y: 843, width: 34, height: 34),
        CGRect(x: 1683, y: 763, width: 34, height: 34),
        CGRect(x: 1003, y: 723, width: 34, height: 34),
        CGRect(x: 283, y: 643, width: 34, height: 34),
        CGRect(x: 2243, y: 643, width: 34, height: 34),
        CGRect(x: 1523, y: 443, width: 34, height: 34),
        CGRect(x: 1723, y: 443, width: 34, height: 34),
        CGRect(x: 2163, y: 443, width: 34, height: 34),
        CGRect(x: 803, y: 403, width: 34, height: 34),
        CGRect(x: 923, y: 363, width: 34, height: 34),
        CGRect(x: 2003, y: 323, width: 34, height: 34),
        CGRect(x: 1203, y: 163, width: 34, height: 34),
        CGRect(x: 1763, y: 163, width: 34, height: 34),
        CGRect(x: 1803, y: 163, width: 34, height: 34),
    ]
}
