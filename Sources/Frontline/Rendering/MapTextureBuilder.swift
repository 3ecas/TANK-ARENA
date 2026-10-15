import SpriteKit

/// Paints the static battlefield into one texture: a city of streets, rooftops and parks,
/// main avenues for the three lanes, a canal and the two military compounds.
@MainActor
enum MapTextureBuilder {
    /// Pixels per world point. The 4000pt map becomes a 2000px texture.
    static let scale: CGFloat = 0.5

    static func texture(for map: MapLayout, city: CityLayout) -> SKTexture {
        TextureFactory.texture("battlefield-city", size: CGSize(width: map.size, height: map.size), scale: scale) { ctx, size in
            ctx.setFillColor(Palette.rgb(0.2, 0.21, 0.22))
            ctx.fill(CGRect(origin: .zero, size: size))
            var rng = SeededRandom(seed: 7)
            drawGroundNoise(ctx, size: size, rng: &rng)
            CityPainter.drawSidewalks(ctx, city: city)
            CityPainter.drawParks(ctx, city: city, rng: &rng)
            drawRiver(ctx, map: map)
            drawLanes(ctx, map: map)
            drawBases(ctx, map: map)
            drawObjectivePads(ctx)
            CityPainter.drawBuildings(ctx, city: city, rng: &rng)
            ctx.strokeRoundedRect(CGRect(origin: .zero, size: size).insetBy(dx: 6, dy: 6), radius: 4,
                                  Palette.rgb(0.08, 0.08, 0.09), width: 12)
        }
    }

    private static func drawGroundNoise(_ ctx: CGContext, size: CGSize, rng: inout SeededRandom) {
        for _ in 0..<350 {
            let p = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let shade = 0.17 + rng.next() * 0.06
            ctx.fillCircle(p, 20 + rng.next() * 70, Palette.rgb(shade, shade, shade + 0.01, 0.35))
        }
    }

    private static func drawRiver(_ ctx: CGContext, map: MapLayout) {
        let start = map.riverStart, end = map.riverEnd
        ctx.strokeLine(start, end, Palette.rgb(0.5, 0.5, 0.48), width: MapConfig.riverWidth + 50)
        ctx.strokeLine(start, end, Palette.rgb(0.17, 0.32, 0.42), width: MapConfig.riverWidth)
        ctx.strokeLine(start, end, Palette.rgb(0.24, 0.42, 0.55, 0.6), width: MapConfig.riverWidth * 0.45)
    }

    private static func drawLanes(_ ctx: CGContext, map: MapLayout) {
        for lane in Lane.allCases {
            let points = map.path(lane, for: .blue).points
            ctx.strokePolyline(points, Palette.rgb(0.45, 0.45, 0.43), width: MapConfig.laneWidth + 36)
            ctx.strokePolyline(points, Palette.rgb(0.15, 0.15, 0.16), width: MapConfig.laneWidth)
            ctx.strokePolyline(points, Palette.rgb(0.85, 0.85, 0.8, 0.5), width: MapConfig.laneWidth - 18)
            ctx.strokePolyline(points, Palette.rgb(0.15, 0.15, 0.16), width: MapConfig.laneWidth - 26)
            ctx.setLineDash(phase: 0, lengths: [40, 40])
            ctx.strokePolyline(points, Palette.rgb(0.95, 0.78, 0.2, 0.85), width: 6)
            ctx.setLineDash(phase: 0, lengths: [])
            if let crossing = riverCrossing(points, map: map) {
                ctx.saveGState()
                ctx.translateBy(x: crossing.point.x, y: crossing.point.y)
                ctx.rotate(by: crossing.angle)
                let bridge = CGRect(x: -MapConfig.riverWidth * 0.8, y: -MapConfig.laneWidth / 2 - 14,
                                    width: MapConfig.riverWidth * 1.6, height: MapConfig.laneWidth + 28)
                ctx.fillRoundedRect(bridge, radius: 4, Palette.rgb(0.42, 0.42, 0.4))
                ctx.fillRoundedRect(bridge.insetBy(dx: 0, dy: 14), radius: 2, Palette.rgb(0.16, 0.16, 0.17))
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
            ctx.fillCircle(center, MapConfig.baseRadius, Palette.rgb(0.36, 0.37, 0.35))
            for ring in stride(from: CGFloat(200), to: MapConfig.baseRadius, by: 140) {
                ctx.strokeCircle(center, ring, Palette.rgb(0.3, 0.31, 0.3), width: 4)
            }
            ctx.strokeCircle(center, MapConfig.baseRadius, Palette.teamCG(team), width: 14)
            ctx.fillCircle(center, 150, Palette.rgb(0.48, 0.5, 0.48))
            ctx.strokeCircle(center, 150, Palette.teamCG(team), width: 6)
            ctx.strokeCircle(center, 70, Palette.rgb(1, 1, 1, 0.8), width: 6)
        }
    }

    private static func drawObjectivePads(_ ctx: CGContext) {
        for camp in ObjectiveConfig.campPositions {
            ctx.fillCircle(camp, 200, Palette.rgb(0.32, 0.31, 0.28))
            for i in 0..<10 {
                let p = camp + CGPoint(angle: CGFloat(i) * .pi / 5, length: 175)
                ctx.fillCircle(p, 16, Palette.sandbag)
            }
        }
        for p in [ObjectiveConfig.radarPosition, ObjectiveConfig.airfieldPosition, ObjectiveConfig.depotPosition] {
            ctx.fillCircle(p, 230, Palette.rgb(0.42, 0.42, 0.4))
            ctx.strokeCircle(p, 230, Palette.rgb(0.28, 0.28, 0.28), width: 8)
        }
        let airfield = ObjectiveConfig.airfieldPosition
        ctx.fillRoundedRect(CGRect(x: airfield.x - 200, y: airfield.y - 35, width: 400, height: 70), radius: 6,
                            Palette.rgb(0.22, 0.22, 0.23))
    }
}
