import CoreGraphics

/// Paints a generated cave map: dusty floor, shaded rock with lit rims, and the spawn pads.
@MainActor
enum CavePainter {
    static func draw(_ ctx: CGContext, size: CGSize, map: ArenaMap, grid: CaveGrid) {
        drawFloor(ctx, size: size, seed: map.seed)
        for team in Team.playable { ArenaPainter.drawSpawn(ctx, zone: map.spawnZone(team), team: team) }
        // Zone pads go under the rock so pillars inside a zone stay visible.
        for zone in map.zoneSpecs { ArenaPainter.drawZonePad(ctx, center: zone.center) }
        drawShadows(ctx, grid: grid)
        drawRock(ctx, grid: grid, seed: map.seed)
    }

    private static func drawFloor(_ ctx: CGContext, size: CGSize, seed: UInt64) {
        ctx.setFillColor(Palette.rgb(0.29, 0.26, 0.23))
        ctx.fill(CGRect(origin: .zero, size: size))
        var rng = SeededRandom(seed: seed &+ 5)
        for _ in 0..<320 {
            let p = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            let shade = 0.24 + rng.next() * 0.08
            ctx.fillCircle(p, 12 + rng.next() * 46, Palette.rgb(shade, shade * 0.9, shade * 0.8, 0.45))
        }
        for _ in 0..<500 {
            let p = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
            ctx.fillCircle(p, 2 + rng.next() * 4, Palette.rgb(0.2, 0.18, 0.16, 0.8))
        }
    }

    /// Dark band on the floor along rock walls (light comes from the top-left).
    private static func drawShadows(_ ctx: CGContext, grid: CaveGrid) {
        let c = grid.cellSize
        let shadow = Palette.rgb(0, 0, 0, 0.35)
        for y in 0..<grid.rows {
            for x in 0..<grid.columns where grid.isRock(x, y) {
                if !grid.isRock(x + 1, y) {
                    ctx.fillRoundedRect(CGRect(x: CGFloat(x + 1) * c, y: CGFloat(y) * c - 8, width: 10, height: c), radius: 2, shadow)
                }
                if !grid.isRock(x, y - 1) {
                    ctx.fillRoundedRect(CGRect(x: CGFloat(x) * c + 8, y: CGFloat(y) * c - 10, width: c, height: 10), radius: 2, shadow)
                }
            }
        }
    }

    private static func drawRock(_ ctx: CGContext, grid: CaveGrid, seed: UInt64) {
        let c = grid.cellSize
        let noise = ValueNoise(seed: UInt32(truncatingIfNeeded: seed &+ 99))
        for y in 0..<grid.rows {
            for x in 0..<grid.columns where grid.isRock(x, y) {
                let rect = CGRect(x: CGFloat(x) * c, y: CGFloat(y) * c, width: c, height: c)
                let n = noise.value(CGFloat(x) / 3, CGFloat(y) / 3)
                let interior = grid.isRock(x - 1, y) && grid.isRock(x + 1, y) && grid.isRock(x, y - 1) && grid.isRock(x, y + 1)
                let base = interior ? 0.11 + n * 0.06 : 0.2 + n * 0.08
                ctx.setFillColor(Palette.rgb(base * 1.05, base * 0.95, base * 0.85))
                ctx.fill(rect.insetBy(dx: -0.5, dy: -0.5))
                drawRims(ctx, grid: grid, x: x, y: y, rect: rect)
            }
        }
    }

    /// Light rim on edges that face open floor.
    private static func drawRims(_ ctx: CGContext, grid: CaveGrid, x: Int, y: Int, rect: CGRect) {
        let light = Palette.rgb(0.48, 0.43, 0.36, 0.9)
        let dark = Palette.rgb(0.08, 0.07, 0.06, 0.9)
        if !grid.isRock(x, y + 1) { ctx.strokeLine(CGPoint(x: rect.minX, y: rect.maxY - 2), CGPoint(x: rect.maxX, y: rect.maxY - 2), light, width: 4) }
        if !grid.isRock(x - 1, y) { ctx.strokeLine(CGPoint(x: rect.minX + 2, y: rect.minY), CGPoint(x: rect.minX + 2, y: rect.maxY), light, width: 4) }
        if !grid.isRock(x, y - 1) { ctx.strokeLine(CGPoint(x: rect.minX, y: rect.minY + 1.5), CGPoint(x: rect.maxX, y: rect.minY + 1.5), dark, width: 3) }
        if !grid.isRock(x + 1, y) { ctx.strokeLine(CGPoint(x: rect.maxX - 1.5, y: rect.minY), CGPoint(x: rect.maxX - 1.5, y: rect.maxY), dark, width: 3) }
    }
}
