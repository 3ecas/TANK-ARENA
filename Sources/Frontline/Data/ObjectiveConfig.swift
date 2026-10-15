import CoreGraphics

enum ObjectiveConfig {
    static let radarPosition = CGPoint(x: 1150, y: 2850)
    static let airfieldPosition = CGPoint(x: 2850, y: 1150)
    static let captureRadius: CGFloat = 200
    /// Seconds for a single team to fully capture an uncontested point.
    static let captureTime: CGFloat = 8
    /// Radar owners: sight multiplier for every unit plus a large reveal around the radar.
    static let radarSightMultiplier: CGFloat = 1.3
    static let radarRevealRadius: CGFloat = 1000
    /// Airfield owners: call-in cooldown multiplier.
    static let airfieldCooldownMultiplier: CGFloat = 0.75

    // Neutral camps
    static let campPositions: [CGPoint] = [
        CGPoint(x: 950, y: 1950), CGPoint(x: 1950, y: 950),
        CGPoint(x: 3050, y: 2050), CGPoint(x: 2050, y: 3050),
    ]
    static let campMembers: [EntityKind] = [.mercenary, .mercenary, .heavyMercenary]
    static let campFirstSpawn: CGFloat = 60
    static let campRespawn: CGFloat = 75
    static let campLeash: CGFloat = 450

    // Heavy Armor Depot
    static let depotPosition = CGPoint(x: 1650, y: 2350)
    static let depotFirstSpawn: CGFloat = 480
    static let depotRespawn: CGFloat = 300
    static let depotLeash: CGFloat = 550
    static let depotTeamGold = 250
    static let depotCommandPoints = 3
}
