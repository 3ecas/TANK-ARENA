import CoreGraphics

/// Breakthrough mode: attackers must capture both zones of sector A, then B, C and D.
/// Spawns move forward as sectors fall. Shared by every map (maps only differ in their obstacles).
enum BreakthroughConfig {
    static let mapSize = CGSize(width: 4800, height: 2400)

    struct SectorSpec {
        let name: String
        let zones: [ZoneConfig.ZoneSpec]
        /// Where attackers spawn while this sector is being attacked.
        let attackerSpawn: CGRect
        /// Where defenders spawn while defending this sector.
        let defenderSpawn: CGRect
        /// Left edge of the sector (for the painted sector boundaries).
        let minX: CGFloat
    }

    /// Zones are at least ~970 points apart from each other, top and bottom of each sector.
    static let sectors: [SectorSpec] = [
        SectorSpec(name: "A", zones: [ZoneConfig.ZoneSpec(name: "A1", center: CGPoint(x: 800, y: 1850)),
                                      ZoneConfig.ZoneSpec(name: "A2", center: CGPoint(x: 1250, y: 550))],
                   attackerSpawn: CGRect(x: 60, y: 1000, width: 300, height: 500),
                   defenderSpawn: CGRect(x: 1650, y: 1050, width: 300, height: 300), minX: 450),
        SectorSpec(name: "B", zones: [ZoneConfig.ZoneSpec(name: "B1", center: CGPoint(x: 1850, y: 1650)),
                                      ZoneConfig.ZoneSpec(name: "B2", center: CGPoint(x: 2300, y: 600))],
                   attackerSpawn: CGRect(x: 900, y: 1030, width: 300, height: 340),
                   defenderSpawn: CGRect(x: 2700, y: 1100, width: 300, height: 300), minX: 1600),
        SectorSpec(name: "C", zones: [ZoneConfig.ZoneSpec(name: "C1", center: CGPoint(x: 2900, y: 1850)),
                                      ZoneConfig.ZoneSpec(name: "C2", center: CGPoint(x: 3300, y: 700))],
                   attackerSpawn: CGRect(x: 2000, y: 1000, width: 300, height: 340),
                   defenderSpawn: CGRect(x: 3700, y: 1050, width: 300, height: 300), minX: 2650),
        SectorSpec(name: "D", zones: [ZoneConfig.ZoneSpec(name: "D1", center: CGPoint(x: 3950, y: 1800)),
                                      ZoneConfig.ZoneSpec(name: "D2", center: CGPoint(x: 4250, y: 500))],
                   attackerSpawn: CGRect(x: 3050, y: 1130, width: 300, height: 340),
                   defenderSpawn: CGRect(x: 4440, y: 950, width: 300, height: 500), minX: 3700),
    ]

    /// Attacker respawns cost one ticket each. With no tickets left, attackers lose once all of them are down.
    static let attackerTickets = 200
    /// Tickets the attackers get back for each sector they capture.
    static let ticketsPerSector = 50
}
