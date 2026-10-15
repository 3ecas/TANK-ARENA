import CoreGraphics

/// Static geometry of the battlefield, derived from `MapConfig`.
struct MapLayout {
    let size: CGFloat
    let bounds: CGRect
    private let bluePaths: [Lane: LanePath]
    private let redPaths: [Lane: LanePath]

    init() {
        size = MapConfig.size
        bounds = CGRect(x: 0, y: 0, width: size, height: size)
        var blue: [Lane: LanePath] = [:]
        var red: [Lane: LanePath] = [:]
        for lane in Lane.allCases {
            let waypoints = MapConfig.blueLaneWaypoints[lane] ?? []
            let path = LanePath(points: [MapConfig.blueHQ] + waypoints + [MapConfig.mirror(MapConfig.blueHQ)])
            blue[lane] = path
            red[lane] = path.reversed()
        }
        bluePaths = blue
        redPaths = red
    }

    func hqPosition(_ team: Team) -> CGPoint {
        team == .red ? MapConfig.mirror(MapConfig.blueHQ) : MapConfig.blueHQ
    }

    func spawnPoint(_ team: Team) -> CGPoint {
        team == .red ? MapConfig.mirror(MapConfig.blueSpawn) : MapConfig.blueSpawn
    }

    /// Lane path walked by `team`'s troops (from their HQ to the enemy HQ).
    func path(_ lane: Lane, for team: Team) -> LanePath {
        let paths = team == .red ? redPaths : bluePaths
        return paths[lane] ?? LanePath(points: [hqPosition(team), hqPosition(team.opponent)])
    }

    func isInBase(_ p: CGPoint, team: Team) -> Bool {
        guard team != .neutral else { return false }
        return p.distance(to: spawnPoint(team)) <= MapConfig.baseRadius
    }

    func nearestLane(to p: CGPoint) -> Lane {
        var best = Lane.mid
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for lane in Lane.allCases {
            let d = path(lane, for: .blue).distance(from: p)
            if d < bestDistance { bestDistance = d; best = lane }
        }
        return best
    }

    /// River runs from the top-left corner to the bottom-right corner.
    var riverStart: CGPoint { CGPoint(x: 0, y: size) }
    var riverEnd: CGPoint { CGPoint(x: size, y: 0) }
}
