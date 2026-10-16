import CoreGraphics

/// "Office": the one hand-made map (2400 x 1520), used by both modes. Compact rooms and a balanced layout: the
/// floor is mirrored top / bottom, so sites A and B are exactly as far from each spawn.
/// Attackers start in the west lobby; doors lead into the north rooms, the middle and the south rooms.
/// Defenders start in the east room, with doors straight into both site rooms and into the middle connector.
enum MapConfig {
    static let size = CGSize(width: 2400, height: 1520)
    static let attackerSpawn = CGRect(x: 48, y: 560, width: 272, height: 400)
    static let defenderSpawn = CGRect(x: 2096, y: 560, width: 256, height: 400)
    static let sites: [ZoneConfig.ZoneSpec] = [
        ZoneConfig.ZoneSpec(name: "A", center: CGPoint(x: 1760, y: 1216)),
        ZoneConfig.ZoneSpec(name: "B", center: CGPoint(x: 1760, y: 304)),
    ]

    /// Walls and pillars (block movement, bullets and sight).
    static let walls: [CGRect] = [
        CGRect(x: 0, y: 0, width: 2400, height: 32),
        CGRect(x: 0, y: 1488, width: 2400, height: 32),
        CGRect(x: 0, y: 0, width: 32, height: 1520),
        CGRect(x: 2368, y: 0, width: 32, height: 1520),
        CGRect(x: 549, y: 32, width: 22, height: 208),
        CGRect(x: 549, y: 384, width: 22, height: 304),
        CGRect(x: 549, y: 832, width: 22, height: 304),
        CGRect(x: 549, y: 1280, width: 22, height: 208),
        CGRect(x: 560, y: 501, width: 224, height: 22),
        CGRect(x: 928, y: 501, width: 288, height: 22),
        CGRect(x: 1360, y: 501, width: 160, height: 22),
        CGRect(x: 560, y: 997, width: 224, height: 22),
        CGRect(x: 928, y: 997, width: 288, height: 22),
        CGRect(x: 1360, y: 997, width: 160, height: 22),
        CGRect(x: 1509, y: 32, width: 22, height: 232),
        CGRect(x: 1509, y: 408, width: 22, height: 104),
        CGRect(x: 1509, y: 1008, width: 22, height: 104),
        CGRect(x: 1509, y: 1256, width: 22, height: 232),
        CGRect(x: 1509, y: 512, width: 22, height: 112),
        CGRect(x: 1509, y: 896, width: 22, height: 112),
        CGRect(x: 1520, y: 501, width: 176, height: 22),
        CGRect(x: 1840, y: 501, width: 160, height: 22),
        CGRect(x: 1520, y: 997, width: 176, height: 22),
        CGRect(x: 1840, y: 997, width: 160, height: 22),
        CGRect(x: 1989, y: 32, width: 22, height: 160),
        CGRect(x: 1989, y: 336, width: 22, height: 176),
        CGRect(x: 1989, y: 1008, width: 22, height: 176),
        CGRect(x: 1989, y: 1328, width: 22, height: 160),
        CGRect(x: 1989, y: 512, width: 22, height: 176),
        CGRect(x: 1989, y: 832, width: 22, height: 176),
        CGRect(x: 1029, y: 32, width: 22, height: 160),
        CGRect(x: 1029, y: 336, width: 22, height: 176),
        CGRect(x: 1029, y: 1008, width: 22, height: 176),
        CGRect(x: 1029, y: 1328, width: 22, height: 160),
        CGRect(x: 1029, y: 512, width: 22, height: 48),
        CGRect(x: 1029, y: 688, width: 22, height: 144),
        CGRect(x: 1029, y: 960, width: 22, height: 48),
        CGRect(x: 560, y: 253, width: 128, height: 22),
        CGRect(x: 832, y: 253, width: 208, height: 22),
        CGRect(x: 560, y: 1245, width: 128, height: 22),
        CGRect(x: 832, y: 1245, width: 208, height: 22),
        CGRect(x: 1280, y: 704, width: 56, height: 112),
        CGRect(x: 1160, y: 304, width: 128, height: 48),
        CGRect(x: 1160, y: 1168, width: 128, height: 48),
    ]

    /// Desks (cover).
    static let desks: [CGRect] = [
        CGRect(x: 704, y: 608, width: 72, height: 35),
        CGRect(x: 1344, y: 784, width: 35, height: 72),
        CGRect(x: 664, y: 112, width: 96, height: 35),
        CGRect(x: 920, y: 416, width: 72, height: 35),
        CGRect(x: 1360, y: 144, width: 35, height: 72),
        CGRect(x: 1600, y: 200, width: 72, height: 35),
        CGRect(x: 1840, y: 416, width: 35, height: 72),
        CGRect(x: 2120, y: 200, width: 72, height: 35),
        CGRect(x: 2160, y: 416, width: 48, height: 48),
        CGRect(x: 1640, y: 736, width: 48, height: 48),
        CGRect(x: 704, y: 877, width: 72, height: 35),
        CGRect(x: 1344, y: 664, width: 35, height: 72),
        CGRect(x: 664, y: 1373, width: 96, height: 35),
        CGRect(x: 920, y: 1069, width: 72, height: 35),
        CGRect(x: 1360, y: 1304, width: 35, height: 72),
        CGRect(x: 1600, y: 1285, width: 72, height: 35),
        CGRect(x: 1840, y: 1032, width: 35, height: 72),
        CGRect(x: 2120, y: 1285, width: 72, height: 35),
        CGRect(x: 2160, y: 1056, width: 48, height: 48),
    ]
}
