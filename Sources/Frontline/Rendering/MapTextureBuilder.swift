import SpriteKit

/// Paints the static battlefield (grass, neutral zones, river, lanes, bases) into one texture.
@MainActor
enum MapTextureBuilder {
    /// Pixels per world point. The 4000pt map becomes a 2000px texture.
    static let scale: CGFloat = 0.5

    static func texture(for map: MapLayout) -> SKTexture {
        TextureFactory.texture("battlefield", size: CGSize(width: map.size, height: map.size), scale: scale) { ctx, size in
            draw(ctx, map: map, size: size)
        }
    }

    private static func draw(_ ctx: CGContext, map: MapLayout, size: CGSize) {
        var rng = SeededRandom(seed: 7)
        ctx.setFillColor(Palette.rgb(0.28, 0.38, 0.22))
        ctx.fill(CGRect(origin: .zero, size: size))

        // Ground variation
        for _ in 0..<500 {
            let p = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let shade = 0.9 + rng.next() * 0.2
            ctx.fillCircle(p, 30 + rng.next() * 90, Palette.rgb(0.27 * shade, 0.37 * shade, 0.21 * shade, 0.5))
        }
        drawNeutralZones(ctx, rng: &rng)
        drawRiver(ctx, map: map)
        drawLanes(ctx, map: map)
        drawBases(ctx, map: map)
        drawObjectivePads(ctx)
        ctx.strokeRoundedRect(CGRect(origin: .zero, size: size).insetBy(dx: 6, dy: 6), radius: 4,
                              Palette.rgb(0.1, 0.12, 0.08), width: 12)
    }

    private static func drawNeutralZones(_ ctx: CGContext, rng: inout SeededRandom) {
        for camp in ObjectiveConfig.campPositions {
            ctx.fillCircle(camp, 230, Palette.rgb(0.23, 0.31, 0.18, 0.8))
            for _ in 0..<26 {
                let p = camp + CGPoint(angle: rng.next() * 2 * .pi, length: 120 + rng.next() * 260)
                ctx.fillCircle(p, 18 + rng.next() * 22, Palette.rgb(0.15, 0.25, 0.13, 0.95))
                ctx.fillCircle(p + CGPoint(x: -4, y: 4), 8, Palette.rgb(0.25, 0.38, 0.2, 0.9))
            }
            ctx.fillCircle(camp, 90, Palette.rgb(0.45, 0.4, 0.28, 0.85))
        }
        // Rocks scattered in the jungle quadrants
        for _ in 0..<60 {
            let p = CGPoint(x: 600 + rng.next() * 2800, y: 600 + rng.next() * 2800)
            if abs(p.x - p.y) < 300 { continue }
            ctx.fillCircle(p, 10 + rng.next() * 16, Palette.rgb(0.42, 0.42, 0.4, 0.9))
        }
    }

    private static func drawRiver(_ ctx: CGContext, map: MapLayout) {
        let start = map.riverStart, end = map.riverEnd
        ctx.strokeLine(start, end, Palette.rgb(0.35, 0.33, 0.24), width: MapConfig.riverWidth + 60)
        ctx.strokeLine(start, end, Palette.rgb(0.2, 0.36, 0.5), width: MapConfig.riverWidth)
        ctx.strokeLine(start, end, Palette.rgb(0.28, 0.46, 0.62, 0.7), width: MapConfig.riverWidth * 0.45)
    }

    private static func drawLanes(_ ctx: CGContext, map: MapLayout) {
        for lane in Lane.allCases {
            let points = map.path(lane, for: .blue).points
            ctx.strokePolyline(points, Palette.rgb(0.42, 0.36, 0.26), width: MapConfig.laneWidth + 24)
            ctx.strokePolyline(points, Palette.rgb(0.56, 0.49, 0.35), width: MapConfig.laneWidth)
            ctx.setLineDash(phase: 0, lengths: [30, 40])
            ctx.strokePolyline(points, Palette.rgb(0.63, 0.56, 0.42), width: 8)
            ctx.setLineDash(phase: 0, lengths: [])
            // Bridges where the lane crosses the river
            if let crossing = riverCrossing(points, map: map) {
                ctx.saveGState()
                ctx.translateBy(x: crossing.point.x, y: crossing.point.y)
                ctx.rotate(by: crossing.angle)
                ctx.fillRoundedRect(CGRect(x: -MapConfig.riverWidth * 0.75, y: -MapConfig.laneWidth / 2,
                                           width: MapConfig.riverWidth * 1.5, height: MapConfig.laneWidth),
                                    radius: 6, Palette.rgb(0.45, 0.35, 0.22))
                ctx.restoreGState()
            }
        }
    }

    private static func riverCrossing(_ points: [CGPoint], map: MapLayout) -> (point: CGPoint, angle: CGFloat)? {
        for i in 0..<(points.count - 1) {
            let a = points[i], b = points[i + 1]
            let sa = a.x + a.y - map.size, sb = b.x + b.y - map.size
            if sa * sb <= 0 && sa != sb {
                let t = sa / (sa - sb)
                return (a.lerp(to: b, t: t), (b - a).angle)
            }
        }
        return nil
    }

    private static func drawBases(_ ctx: CGContext, map: MapLayout) {
        for team in Team.playable {
            let center = map.spawnPoint(team)
            ctx.fillCircle(center, MapConfig.baseRadius, Palette.rgb(0.42, 0.43, 0.42, 0.55))
            ctx.strokeCircle(center, MapConfig.baseRadius, Palette.teamCG(team), width: 10)
            ctx.fillCircle(center, 150, Palette.rgb(0.5, 0.52, 0.5))
            ctx.strokeCircle(center, 150, Palette.teamCG(team), width: 6)
            ctx.fillCircle(center, 60, Palette.teamCG(team))
        }
    }

    private static func drawObjectivePads(_ ctx: CGContext) {
        for p in [ObjectiveConfig.radarPosition, ObjectiveConfig.airfieldPosition, ObjectiveConfig.depotPosition] {
            ctx.fillCircle(p, 230, Palette.rgb(0.45, 0.45, 0.43, 0.9))
            ctx.strokeCircle(p, 230, Palette.rgb(0.3, 0.3, 0.3), width: 8)
        }
        let airfield = ObjectiveConfig.airfieldPosition
        ctx.fillRoundedRect(CGRect(x: airfield.x - 200, y: airfield.y - 35, width: 400, height: 70), radius: 6,
                            Palette.rgb(0.25, 0.25, 0.26))
    }
}

/// Deterministic random numbers so the map looks the same every game.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }

    /// Uniform value in 0..<1.
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 1_000_000) / 1_000_000
    }
}
