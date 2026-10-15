import CoreGraphics

/// Builds a cave system: noise-shaped rock, two winding outer tunnels across the map, a middle
/// route snaking through every zone and spawn, and narrow side passages between them.
/// Anything not reachable through passages at least two cells wide is filled with rock.
struct CaveGenerator {
    let size: CGSize
    /// Spawn rectangles; the first one is where the flood fill starts.
    let spawns: [CGRect]
    let zones: [CGPoint]
    private var rng: SeededRandom
    private var grid: CaveGrid
    private let noise: ValueNoise

    init(seed: UInt64, size: CGSize, spawns: [CGRect], zones: [CGPoint]) {
        self.size = size
        self.spawns = spawns
        self.zones = zones
        rng = SeededRandom(seed: seed)
        grid = CaveGrid(size: size, cellSize: CaveConfig.cellSize)
        noise = ValueNoise(seed: UInt32(truncatingIfNeeded: seed))
    }

    mutating func generate() -> CaveGrid {
        fillNoise()
        carveLanes()
        carveConnectors()
        for zone in zones { grid.carve(zone, radius: CaveConfig.zoneClearing) }
        for spawn in spawns { grid.carve(spawn, margin: 30) }
        addPillars()
        sealBorder()
        for spawn in spawns { grid.carve(spawn) }
        keepReachable()
        return grid
    }

    private func range(_ r: ClosedRange<CGFloat>, _ value: CGFloat) -> CGFloat {
        r.lowerBound + (r.upperBound - r.lowerBound) * value
    }

    private mutating func random(_ r: ClosedRange<CGFloat>) -> CGFloat {
        range(r, rng.next())
    }

    private mutating func fillNoise() {
        let w = CaveConfig.noiseWeightLarge
        for y in 0..<grid.rows {
            for x in 0..<grid.columns {
                let fx = CGFloat(x), fy = CGFloat(y)
                let n = noise.value(fx / CaveConfig.noiseScaleLarge, fy / CaveConfig.noiseScaleLarge) * w
                    + noise.value(fx / CaveConfig.noiseScaleSmall + 91, fy / CaveConfig.noiseScaleSmall + 37) * (1 - w)
                grid.set(x, y, rock: n > CaveConfig.rockThreshold)
            }
        }
    }

    private mutating func carvePath(_ points: [CGPoint], radius: ClosedRange<CGFloat>) {
        for (a, b) in zip(points, points.dropFirst()) {
            let steps = Swift.max(1, Int(a.distance(to: b) / 15))
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let r = random(radius)
                grid.carve(a + (b - a) * t, radius: r)
            }
        }
    }

    private mutating func carveLanes() {
        guard let first = spawns.first, let last = spawns.max(by: { $0.midX < $1.midX }) else { return }
        let start = CGPoint(x: first.midX, y: first.midY)
        let end = CGPoint(x: last.midX, y: last.midY)
        for laneY in CaveConfig.laneYs {
            var points = [start]
            var x = start.x + 260
            while x < end.x - 260 {
                points.append(CGPoint(x: x + random(-60...60), y: laneY + random(-CaveConfig.laneJitter...CaveConfig.laneJitter)))
                x += random(CaveConfig.laneStep)
            }
            points.append(end)
            carvePath(points, radius: CaveConfig.routeRadius)
        }
        // Middle route: every zone and spawn in order from left to right.
        let stops = (zones + spawns.map { CGPoint(x: $0.midX, y: $0.midY) }).sorted { $0.x < $1.x }
        carvePath(stops, radius: CaveConfig.middleRadius)
    }

    /// Wiggly narrow passages between neighbouring routes.
    private mutating func carveConnectors() {
        let rows = (CaveConfig.laneYs + [size.height / 2]).sorted()
        let wiggle = CaveConfig.connectorWiggle
        for (y0, y1) in zip(rows, rows.dropFirst()) {
            let counts = CaveConfig.connectorsPerGap
            let count = Swift.min(counts.upperBound,
                                  counts.lowerBound + Int(rng.next() * CGFloat(counts.upperBound - counts.lowerBound + 1)))
            for _ in 0..<count {
                let x = random(450...(size.width - 450))
                var points = [CGPoint(x: x, y: y0)]
                for k in 1...3 {
                    points.append(CGPoint(x: x + random(-wiggle...wiggle), y: y0 + (y1 - y0) * CGFloat(k) / 4))
                }
                points.append(CGPoint(x: x + random(-60...60), y: y1))
                carvePath(points, radius: CaveConfig.connectorRadius)
            }
        }
    }

    private mutating func addPillars() {
        for zone in zones {
            for _ in 0..<CaveConfig.zonePillars {
                let angle = random(0...(2 * .pi))
                let p = zone + CGPoint(angle: angle, length: random(CaveConfig.pillarDistance))
                let (x, y) = grid.cell(of: p)
                grid.set(x, y, rock: true)
            }
        }
    }

    private mutating func sealBorder() {
        for x in 0..<grid.columns {
            grid.set(x, 0, rock: true)
            grid.set(x, grid.rows - 1, rock: true)
        }
        for y in 0..<grid.rows {
            grid.set(0, y, rock: true)
            grid.set(grid.columns - 1, y, rock: true)
        }
    }

    /// Flood fill over 2x2 open blocks from the blue spawn, so every remaining passage is
    /// at least two cells wide; everything else becomes rock.
    private mutating func keepReachable() {
        let columns = grid.columns, rows = grid.rows
        let snapshot = grid
        func isBlock(_ x: Int, _ y: Int) -> Bool {
            x > 0 && y > 0 && x < columns - 2 && y < rows - 2
                && !snapshot.isRock(x, y) && !snapshot.isRock(x + 1, y)
                && !snapshot.isRock(x, y + 1) && !snapshot.isRock(x + 1, y + 1)
        }
        guard let first = spawns.first else { return }
        let (sx, sy) = grid.cell(of: CGPoint(x: first.midX, y: first.midY))
        var seen = [Bool](repeating: false, count: columns * rows)
        var keep = [Bool](repeating: false, count: columns * rows)
        var queue = [(sx, sy)]
        seen[sy * columns + sx] = true
        var head = 0
        while head < queue.count {
            let (x, y) = queue[head]
            head += 1
            for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)] { keep[(y + dy) * columns + x + dx] = true }
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let nx = x + dx, ny = y + dy
                guard isBlock(nx, ny), !seen[ny * columns + nx] else { continue }
                seen[ny * columns + nx] = true
                queue.append((nx, ny))
            }
        }
        for i in keep.indices { grid.rock[i] = !keep[i] }
    }
}
