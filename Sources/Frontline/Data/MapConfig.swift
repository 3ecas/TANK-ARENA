import CoreGraphics

/// Hand-made city map. Deliberately irregular and not mirrored: few buildings of different sizes,
/// open plazas, roads, crates and wrecks. Blue spawns bottom-left, red top-right.
enum MapConfig {
    static let size = CGSize(width: 2800, height: 1800)
    static let blueSpawn = CGRect(x: 60, y: 120, width: 280, height: 420)
    static let redSpawn = CGRect(x: 2460, y: 1260, width: 280, height: 420)

    /// Buildings (x, y, width, height). Touching rectangles form L-shaped blocks.
    static let buildings: [CGRect] = [
        CGRect(x: 380, y: 1000, width: 360, height: 280),
        CGRect(x: 110, y: 1440, width: 300, height: 300),
        CGRect(x: 880, y: 140, width: 420, height: 250),
        CGRect(x: 1020, y: 480, width: 190, height: 400),
        CGRect(x: 560, y: 1480, width: 260, height: 190),
        CGRect(x: 820, y: 1420, width: 130, height: 340),
        CGRect(x: 1260, y: 1460, width: 480, height: 220),
        CGRect(x: 1640, y: 180, width: 300, height: 400),
        CGRect(x: 1980, y: 560, width: 170, height: 150),
        CGRect(x: 2330, y: 250, width: 360, height: 300),
        CGRect(x: 1920, y: 1440, width: 300, height: 240),
        CGRect(x: 2500, y: 640, width: 200, height: 330),
        CGRect(x: 1150, y: 1080, width: 140, height: 130),
    ]

    /// Crates and low cover.
    static let crates: [CGRect] = [
        CGRect(x: 560, y: 820, width: 44, height: 44),
        CGRect(x: 860, y: 700, width: 40, height: 70),
        CGRect(x: 300, y: 700, width: 60, height: 40),
        CGRect(x: 1300, y: 820, width: 50, height: 50),
        CGRect(x: 1560, y: 880, width: 40, height: 80),
        CGRect(x: 1700, y: 1180, width: 60, height: 40),
        CGRect(x: 1380, y: 1300, width: 50, height: 40),
        CGRect(x: 2080, y: 1000, width: 50, height: 50),
        CGRect(x: 2300, y: 1100, width: 40, height: 60),
        CGRect(x: 2380, y: 700, width: 60, height: 40),
        CGRect(x: 800, y: 1100, width: 40, height: 40),
        CGRect(x: 1820, y: 760, width: 40, height: 60),
        CGRect(x: 600, y: 320, width: 50, height: 50),
        CGRect(x: 2650, y: 1120, width: 50, height: 40),
    ]

    /// Wrecked cars, sandbag walls and barricades.
    static let barriers: [CGRect] = [
        CGRect(x: 1280, y: 600, width: 110, height: 40),
        CGRect(x: 940, y: 950, width: 36, height: 110),
        CGRect(x: 1830, y: 1000, width: 120, height: 36),
        CGRect(x: 2060, y: 380, width: 40, height: 120),
        CGRect(x: 480, y: 460, width: 120, height: 30),
        CGRect(x: 2150, y: 1300, width: 36, height: 100),
        CGRect(x: 1560, y: 640, width: 90, height: 36),
        CGRect(x: 260, y: 1180, width: 30, height: 110),
    ]

    /// Asphalt strips painted under everything (purely visual).
    static let roads: [CGRect] = [
        CGRect(x: 0, y: 855, width: 2800, height: 90),
        CGRect(x: 1385, y: 0, width: 90, height: 1800),
        CGRect(x: 0, y: 400, width: 1000, height: 80),
        CGRect(x: 1900, y: 1220, width: 900, height: 80),
        CGRect(x: 2200, y: 0, width: 80, height: 1800),
    ]
}
