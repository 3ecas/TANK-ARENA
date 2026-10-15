import SpriteKit

/// Paints the static arena into one texture: streets, sidewalks, rooftops, crates and spawn zones.
@MainActor
enum ArenaPainter {
    static let scale: CGFloat = 0.6

    private static let roofColors: [CGColor] = [
        Palette.rgb(0.52, 0.52, 0.5), Palette.rgb(0.47, 0.42, 0.37), Palette.rgb(0.38, 0.41, 0.45),
        Palette.rgb(0.56, 0.48, 0.38), Palette.rgb(0.42, 0.45, 0.4),
    ]

    static func texture(for map: ArenaMap) -> SKTexture {
        TextureFactory.texture("arena", size: map.size, scale: scale) { ctx, size in
            ctx.setFillColor(Palette.rgb(0.25, 0.25, 0.26))
            ctx.fill(CGRect(origin: .zero, size: size))
            drawStreetMarkings(ctx, size: size)
            for team in Team.playable { drawSpawn(ctx, zone: map.spawnZone(team), team: team) }
            for zone in ZoneConfig.zones { drawZonePad(ctx, center: zone.center) }
            for obstacle in map.obstacles where obstacle.kind == .building {
                ctx.fillRoundedRect(obstacle.rect.insetBy(dx: -12, dy: -12), radius: 6, Palette.rgb(0.42, 0.42, 0.41))
            }
            for (index, obstacle) in map.obstacles.enumerated() {
                switch obstacle.kind {
                case .building: drawBuilding(ctx, rect: obstacle.rect, style: index)
                case .crate: drawCrate(ctx, rect: obstacle.rect)
                case .barrier: drawBarrier(ctx, rect: obstacle.rect, style: index)
                }
            }
            ctx.strokeRoundedRect(CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4), radius: 4,
                                  Palette.rgb(0.08, 0.08, 0.09), width: 8)
        }
    }

    private static func drawStreetMarkings(_ ctx: CGContext, size: CGSize) {
        var rng = SeededRandom(seed: 11)
        for _ in 0..<260 {
            let p = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let shade = 0.21 + rng.next() * 0.06
            ctx.fillCircle(p, 15 + rng.next() * 50, Palette.rgb(shade, shade, shade + 0.01, 0.4))
        }
        ctx.setLineDash(phase: 0, lengths: [36, 30])
        ctx.strokeLine(CGPoint(x: 300, y: size.height / 2), CGPoint(x: size.width - 300, y: size.height / 2),
                       Palette.rgb(0.9, 0.75, 0.25, 0.7), width: 5)
        ctx.setLineDash(phase: 0, lengths: [])
        // Crosswalks at the alley mouths
        for x in [CGFloat(800), 1400, 2000] {
            for i in 0..<6 {
                let rect = CGRect(x: x - 50 + CGFloat(i) * 18, y: size.height / 2 - 140, width: 9, height: 60)
                ctx.fillRoundedRect(rect, radius: 1, Palette.rgb(0.85, 0.85, 0.82, 0.5))
            }
        }
    }

    private static func drawSpawn(_ ctx: CGContext, zone: CGRect, team: Team) {
        ctx.fillRoundedRect(zone, radius: 10, Palette.rgb(0.32, 0.33, 0.32))
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: zone, cornerWidth: 10, cornerHeight: 10, transform: nil))
        ctx.clip()
        var x = zone.minX - zone.height
        while x < zone.maxX {
            ctx.strokeLine(CGPoint(x: x, y: zone.minY), CGPoint(x: x + zone.height, y: zone.maxY),
                           Palette.teamCG(team).copy(alpha: 0.25) ?? Palette.teamCG(team), width: 10)
            x += 40
        }
        ctx.restoreGState()
        ctx.strokeRoundedRect(zone, radius: 10, Palette.teamCG(team), width: 6)
    }

    private static func drawBuilding(_ ctx: CGContext, rect: CGRect, style: Int) {
        ctx.fillRoundedRect(rect.offsetBy(dx: 10, dy: -10), radius: 3, Palette.rgb(0, 0, 0, 0.45))
        ctx.fillRoundedRect(rect, radius: 3, roofColors[style % roofColors.count])
        ctx.strokeRoundedRect(rect, radius: 3, Palette.rgb(0.1, 0.1, 0.1, 0.85), width: 5)
        let inner = rect.insetBy(dx: 10, dy: 10)
        ctx.strokeRoundedRect(inner, radius: 2, Palette.rgb(1, 1, 1, 0.12), width: 3)
        // Rooftop units
        let count = 2 + style % 3
        for i in 0..<count {
            let w: CGFloat = 18 + CGFloat((style + i) % 3) * 6
            let x = inner.minX + CGFloat((i * 53 + style * 17) % Int(Swift.max(inner.width - w, 1)))
            let y = inner.minY + CGFloat((i * 37 + style * 29) % Int(Swift.max(inner.height - w, 1)))
            ctx.fillRoundedRect(CGRect(x: x, y: y, width: w, height: w), radius: 2, Palette.rgb(0.66, 0.66, 0.64))
            ctx.strokeCircle(CGPoint(x: x + w / 2, y: y + w / 2), w * 0.3, Palette.rgb(0.3, 0.3, 0.3), width: 2)
        }
    }

    private static func drawCrate(_ ctx: CGContext, rect: CGRect) {
        ctx.fillRoundedRect(rect.offsetBy(dx: 5, dy: -5), radius: 2, Palette.rgb(0, 0, 0, 0.4))
        ctx.fillRoundedRect(rect, radius: 2, Palette.rgb(0.55, 0.4, 0.22))
        ctx.strokeRoundedRect(rect, radius: 2, Palette.rgb(0.3, 0.2, 0.1), width: 3)
        ctx.strokeLine(CGPoint(x: rect.minX + 3, y: rect.minY + 3), CGPoint(x: rect.maxX - 3, y: rect.maxY - 3),
                       Palette.rgb(0.35, 0.25, 0.12), width: 3)
        ctx.strokeLine(CGPoint(x: rect.minX + 3, y: rect.maxY - 3), CGPoint(x: rect.maxX - 3, y: rect.minY + 3),
                       Palette.rgb(0.35, 0.25, 0.12), width: 3)
    }

    /// Painted capture circle under each control zone (the live ownership ring is drawn by ZoneRenderer).
    private static func drawZonePad(_ ctx: CGContext, center: CGPoint) {
        ctx.fillCircle(center, ZoneConfig.radius, Palette.rgb(0.3, 0.31, 0.3))
        ctx.setLineDash(phase: 0, lengths: [18, 14])
        ctx.strokeCircle(center, ZoneConfig.radius - 6, Palette.rgb(0.85, 0.85, 0.8, 0.45), width: 4)
        ctx.setLineDash(phase: 0, lengths: [])
    }

    /// Irregular cover: wrecked cars (even) and sandbag walls (odd).
    private static func drawBarrier(_ ctx: CGContext, rect: CGRect, style: Int) {
        ctx.fillRoundedRect(rect.offsetBy(dx: 5, dy: -5), radius: 4, Palette.rgb(0, 0, 0, 0.4))
        if style % 2 == 0 {
            let body = Palette.rgb(0.32 + CGFloat(style % 3) * 0.08, 0.2, 0.18)
            ctx.fillRoundedRect(rect, radius: 6, body)
            ctx.strokeRoundedRect(rect, radius: 6, Palette.rgb(0.12, 0.1, 0.1), width: 3)
            ctx.fillRoundedRect(rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.22), radius: 3,
                                Palette.rgb(0.15, 0.18, 0.22))
        } else {
            ctx.fillRoundedRect(rect, radius: 5, Palette.sandbag)
            ctx.strokeRoundedRect(rect, radius: 5, Palette.rgb(0.45, 0.38, 0.24), width: 3)
            let horizontal = rect.width >= rect.height
            let length = horizontal ? rect.width : rect.height
            var offset: CGFloat = 16
            while offset < length - 6 {
                let a = horizontal ? CGPoint(x: rect.minX + offset, y: rect.minY + 3) : CGPoint(x: rect.minX + 3, y: rect.minY + offset)
                let b = horizontal ? CGPoint(x: rect.minX + offset, y: rect.maxY - 3) : CGPoint(x: rect.maxX - 3, y: rect.minY + offset)
                ctx.strokeLine(a, b, Palette.rgb(0.5, 0.43, 0.28), width: 2)
                offset += 16
            }
        }
    }
}
