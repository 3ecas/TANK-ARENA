import CoreGraphics

/// "Office": the one hand-made map (3000 x 1900), used by both modes. Few, large rooms and a balanced layout:
/// the floor is mirrored top / bottom, so sites A and B are exactly as far from each spawn.
/// Attackers start in the west lobby; three doors lead into the north hall, the open-plan middle and the south hall.
/// Defenders start in the east room, with doors straight into both site rooms and into the middle connector.
enum MapConfig {
    static let size = CGSize(width: 3000, height: 1900)
    static let attackerSpawn = CGRect(x: 60, y: 700, width: 340, height: 500)
    static let defenderSpawn = CGRect(x: 2620, y: 700, width: 320, height: 500)
    static let sites: [ZoneConfig.ZoneSpec] = [
        ZoneConfig.ZoneSpec(name: "A", center: CGPoint(x: 2200, y: 1520)),
        ZoneConfig.ZoneSpec(name: "B", center: CGPoint(x: 2200, y: 380)),
    ]

    /// Walls and pillars (block movement, bullets and sight).
    static let walls: [CGRect] = [
        CGRect(x: 0, y: 0, width: 3000, height: 40),
        CGRect(x: 0, y: 1860, width: 3000, height: 40),
        CGRect(x: 0, y: 0, width: 40, height: 1900),
        CGRect(x: 2960, y: 0, width: 40, height: 1900),
        CGRect(x: 686, y: 40, width: 28, height: 260),
        CGRect(x: 686, y: 480, width: 28, height: 380),
        CGRect(x: 686, y: 1040, width: 28, height: 380),
        CGRect(x: 686, y: 1600, width: 28, height: 260),
        CGRect(x: 700, y: 626, width: 280, height: 28),
        CGRect(x: 1160, y: 626, width: 360, height: 28),
        CGRect(x: 1700, y: 626, width: 200, height: 28),
        CGRect(x: 700, y: 1246, width: 280, height: 28),
        CGRect(x: 1160, y: 1246, width: 360, height: 28),
        CGRect(x: 1700, y: 1246, width: 200, height: 28),
        CGRect(x: 1886, y: 40, width: 28, height: 290),
        CGRect(x: 1886, y: 510, width: 28, height: 130),
        CGRect(x: 1886, y: 1260, width: 28, height: 130),
        CGRect(x: 1886, y: 1570, width: 28, height: 290),
        CGRect(x: 1886, y: 640, width: 28, height: 140),
        CGRect(x: 1886, y: 1120, width: 28, height: 140),
        CGRect(x: 1900, y: 626, width: 220, height: 28),
        CGRect(x: 2300, y: 626, width: 200, height: 28),
        CGRect(x: 1900, y: 1246, width: 220, height: 28),
        CGRect(x: 2300, y: 1246, width: 200, height: 28),
        CGRect(x: 2486, y: 40, width: 28, height: 200),
        CGRect(x: 2486, y: 420, width: 28, height: 220),
        CGRect(x: 2486, y: 1260, width: 28, height: 220),
        CGRect(x: 2486, y: 1660, width: 28, height: 200),
        CGRect(x: 2486, y: 640, width: 28, height: 220),
        CGRect(x: 2486, y: 1040, width: 28, height: 220),
        CGRect(x: 1240, y: 880, width: 70, height: 140),
        CGRect(x: 1600, y: 720, width: 140, height: 60),
        CGRect(x: 1050, y: 180, width: 60, height: 160),
        CGRect(x: 1450, y: 380, width: 160, height: 60),
        CGRect(x: 1600, y: 1120, width: 140, height: 60),
        CGRect(x: 1050, y: 1560, width: 60, height: 160),
        CGRect(x: 1450, y: 1460, width: 160, height: 60),
    ]

    /// Desks (cover).
    static let desks: [CGRect] = [
        CGRect(x: 880, y: 760, width: 90, height: 44),
        CGRect(x: 1680, y: 980, width: 44, height: 90),
        CGRect(x: 830, y: 140, width: 120, height: 44),
        CGRect(x: 1250, y: 520, width: 90, height: 44),
        CGRect(x: 1700, y: 180, width: 44, height: 90),
        CGRect(x: 2000, y: 250, width: 90, height: 44),
        CGRect(x: 2300, y: 520, width: 44, height: 90),
        CGRect(x: 2650, y: 250, width: 90, height: 44),
        CGRect(x: 2700, y: 520, width: 60, height: 60),
        CGRect(x: 2050, y: 900, width: 60, height: 60),
        CGRect(x: 880, y: 1096, width: 90, height: 44),
        CGRect(x: 1680, y: 830, width: 44, height: 90),
        CGRect(x: 830, y: 1716, width: 120, height: 44),
        CGRect(x: 1250, y: 1336, width: 90, height: 44),
        CGRect(x: 1700, y: 1630, width: 44, height: 90),
        CGRect(x: 2000, y: 1606, width: 90, height: 44),
        CGRect(x: 2300, y: 1290, width: 44, height: 90),
        CGRect(x: 2650, y: 1606, width: 90, height: 44),
        CGRect(x: 2700, y: 1320, width: 60, height: 60),
        CGRect(x: 2050, y: 940, width: 60, height: 60),
    ]
}
