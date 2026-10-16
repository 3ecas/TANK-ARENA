import SpriteKit

/// Paints the static arena into one texture: streets, sidewalks, rooftops, crates and spawn zones.
@MainActor
enum ArenaPainter {
    static let scale: CGFloat = 0.6

    private static let roofColors: [CGColor] = [
        Palette.rgb(0.52, 0.52, 0.5), Palette.rgb(0.47, 0.42, 0.37), Palette.rgb(0.38, 0.41, 0.45),
        Palette.rgb(0.56, 0.48, 0.38), Palette.rgb(0.42, 0.45, 0.4),
    ]

    /// Cave maps are new every battle, so only the latest cave texture is kept.
    private static var caveTexture: (seed: UInt64, texture: SKTexture)?

    static func texture(for map: ArenaMap) -> SKTexture {
        if map.kind == .caves, let grid = map.cave {
            if let cached = caveTexture, cached.seed == map.seed { return cached.texture }
            let texture = TextureFactory.render(size: map.size, scale: scale) { ctx, size in
                CavePainter.draw(ctx, size: size, map: map, grid: grid)
            }
            caveTexture = (map.seed, texture)
            return texture
        }
        return TextureFactory.texture("compound", size: map.size, scale: scale) { ctx, size in
            drawFloor(ctx, size: size)
            drawSitesAndSpawns(ctx, map: map)
            for obstacle in map.obstacles where obstacle.kind == .wall {
                ctx.fillRoundedRect(obstacle.rect.offsetBy(dx: 8, dy: -8), radius: 2, Palette.rgb(0, 0, 0, 0.35))
            }
            for (index, obstacle) in map.obstacles.enumerated() {
                switch obstacle.kind {
                case .building: drawBuilding(ctx, rect: obstacle.rect, style: index)
                case .crate: drawCrate(ctx, rect: obstacle.rect)
                case .barrier: drawBarrier(ctx, rect: obstacle.rect, style: index)
                case .rock: ctx.fillRoundedRect(obstacle.rect, radius: 2, Palette.rgb(0.16, 0.14, 0.12))
                case .wall: drawWall(ctx, rect: obstacle.rect)
                }
            }
        }
    }

    /// Indoor floor: concrete tiles with faint seams and stains.
    private static func drawFloor(_ ctx: CGContext, size: CGSize) {
        ctx.setFillColor(Palette.rgb(0.42, 0.41, 0.38))
        ctx.fill(CGRect(origin: .zero, size: size))
        var rng = SeededRandom(seed: 21)
        for _ in 0..<160 {
            let p = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let shade = 0.36 + rng.next() * 0.08
            ctx.fillCircle(p, 12 + rng.next() * 40, Palette.rgb(shade, shade * 0.98, shade * 0.92, 0.35))
        }
        let seam = Palette.rgb(0.3, 0.3, 0.28, 0.5)
        var x: CGFloat = 0
        while x <= size.width {
            ctx.strokeLine(CGPoint(x: x, y: 0), CGPoint(x: x, y: size.height), seam, width: 2)
            x += 80
        }
        var y: CGFloat = 0
        while y <= size.height {
            ctx.strokeLine(CGPoint(x: 0, y: y), CGPoint(x: size.width, y: y), seam, width: 2)
            y += 80
        }
    }

    /// Thick concrete wall with a lit top edge.
    private static func drawWall(_ ctx: CGContext, rect: CGRect) {
        ctx.setFillColor(Palette.rgb(0.17, 0.18, 0.2))
        ctx.fill(rect)
        ctx.strokeLine(CGPoint(x: rect.minX, y: rect.maxY - 2), CGPoint(x: rect.maxX, y: rect.maxY - 2),
                       Palette.rgb(0.4, 0.42, 0.45, 0.8), width: 3)
        ctx.strokeLine(CGPoint(x: rect.minX + 2, y: rect.minY), CGPoint(x: rect.minX + 2, y: rect.maxY),
                       Palette.rgb(0.32, 0.34, 0.37, 0.6), width: 3)
    }

    /// Both spawn pads and the bomb site pads.
    static func drawSitesAndSpawns(_ ctx: CGContext, map: ArenaMap) {
        for spawn in map.allSpawns { drawSpawn(ctx, zone: spawn) }
        for site in map.siteSpecs { drawZonePad(ctx, center: site.center) }
    }

    static func drawSpawn(_ ctx: CGContext, zone: CGRect) {
        let stripe = Palette.rgb(0.9, 0.9, 0.85, 0.12)
        ctx.fillRoundedRect(zone, radius: 10, Palette.rgb(0.33, 0.34, 0.33))
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
    static func drawZonePad(_ ctx: CGContext, center: CGPoint) {
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
