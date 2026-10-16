import SpriteKit

/// Paints the office floor into one texture: carpet, spawn pads, site pads, partition walls and desks.
@MainActor
enum ArenaPainter {
    static let scale: CGFloat = 0.6
    private static var cached: (seed: UInt64, texture: SKTexture)?

    static func texture(for map: ArenaMap) -> SKTexture {
        if let cached = cached, cached.seed == map.seed { return cached.texture }
        let texture = TextureFactory.render(size: map.size, scale: scale) { ctx, size in
            drawOffice(ctx, size: size, map: map)
        }
        cached = (map.seed, texture)
        return texture
    }

    private static func drawOffice(_ ctx: CGContext, size: CGSize, map: ArenaMap) {
        ctx.setFillColor(Palette.rgb(0.3, 0.33, 0.38))
        ctx.fill(CGRect(origin: .zero, size: size))
        var rng = SeededRandom(seed: map.seed &+ 3)
        let specks = Int(size.width * size.height / 4000)
        for _ in 0..<specks {
            let p = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            ctx.fillCircle(p, 2 + rng.next() * 3, Palette.rgb(0.26, 0.29, 0.34, 0.6))
        }
        for spawn in map.allSpawns { drawSpawn(ctx, zone: spawn) }
        for site in map.siteSpecs { drawSitePad(ctx, center: site.center) }
        for obstacle in map.obstacles where obstacle.kind == .wall {
            ctx.fillRoundedRect(obstacle.rect.offsetBy(dx: 6, dy: -6), radius: 2, Palette.rgb(0, 0, 0, 0.3))
        }
        for (index, obstacle) in map.obstacles.enumerated() {
            switch obstacle.kind {
            case .wall:
                ctx.setFillColor(Palette.rgb(0.78, 0.78, 0.74))
                ctx.fill(obstacle.rect)
                ctx.strokeRoundedRect(obstacle.rect, radius: 1, Palette.rgb(0.5, 0.5, 0.48), width: 2)
            case .desk:
                drawDesk(ctx, rect: obstacle.rect, style: index)
            }
        }
    }

    /// Wooden desk with a monitor.
    private static func drawDesk(_ ctx: CGContext, rect: CGRect, style: Int) {
        ctx.fillRoundedRect(rect.offsetBy(dx: 4, dy: -4), radius: 3, Palette.rgb(0, 0, 0, 0.35))
        ctx.fillRoundedRect(rect, radius: 3, Palette.rgb(0.55 + CGFloat(style % 3) * 0.04, 0.42, 0.28))
        ctx.strokeRoundedRect(rect, radius: 3, Palette.rgb(0.3, 0.22, 0.14), width: 2)
        let screen = CGRect(x: rect.midX - 12, y: rect.midY - 6, width: 24, height: 12)
        ctx.fillRoundedRect(screen, radius: 2, Palette.rgb(0.12, 0.14, 0.18))
        ctx.fillRoundedRect(screen.insetBy(dx: 2, dy: 2), radius: 1, Palette.rgb(0.35, 0.6, 0.85, 0.8))
    }

    /// Striped spawn pad.
    private static func drawSpawn(_ ctx: CGContext, zone: CGRect) {
        let stripe = Palette.rgb(0.9, 0.9, 0.85, 0.12)
        ctx.fillRoundedRect(zone, radius: 10, Palette.rgb(0.33, 0.34, 0.36))
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: zone, cornerWidth: 10, cornerHeight: 10, transform: nil))
        ctx.clip()
        var x = zone.minX - zone.height
        while x < zone.maxX {
            ctx.strokeLine(CGPoint(x: x, y: zone.minY), CGPoint(x: x + zone.height, y: zone.maxY), stripe, width: 10)
            x += 40
        }
        ctx.restoreGState()
        ctx.strokeRoundedRect(zone, radius: 10, Palette.rgb(0.75, 0.75, 0.7, 0.6), width: 4)
    }

    /// Painted circle under a bomb site / rush station (the live ring is drawn by SiteRenderer).
    private static func drawSitePad(_ ctx: CGContext, center: CGPoint) {
        ctx.fillCircle(center, ZoneConfig.radius, Palette.rgb(0.34, 0.31, 0.32))
        ctx.setLineDash(phase: 0, lengths: [18, 14])
        ctx.strokeCircle(center, ZoneConfig.radius - 6, Palette.rgb(0.9, 0.6, 0.5, 0.45), width: 4)
        ctx.setLineDash(phase: 0, lengths: [])
    }
}
