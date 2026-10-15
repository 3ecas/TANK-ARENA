import CoreGraphics

/// Rock / open cells of the cave map.
struct CaveGrid {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    var rock: [Bool]

    init(size: CGSize, cellSize: CGFloat) {
        self.cellSize = cellSize
        columns = Int(size.width / cellSize)
        rows = Int(size.height / cellSize)
        rock = Array(repeating: true, count: columns * rows)
    }

    func isRock(_ x: Int, _ y: Int) -> Bool {
        guard x >= 0, y >= 0, x < columns, y < rows else { return true }
        return rock[y * columns + x]
    }

    mutating func set(_ x: Int, _ y: Int, rock value: Bool) {
        guard x >= 0, y >= 0, x < columns, y < rows else { return }
        rock[y * columns + x] = value
    }

    func center(_ x: Int, _ y: Int) -> CGPoint {
        CGPoint(x: (CGFloat(x) + 0.5) * cellSize, y: (CGFloat(y) + 0.5) * cellSize)
    }

    func cell(of p: CGPoint) -> (Int, Int) {
        (Int(p.x / cellSize), Int(p.y / cellSize))
    }

    /// Opens every cell whose centre is within `radius` of `p`.
    mutating func carve(_ p: CGPoint, radius: CGFloat) {
        let minX = Int((p.x - radius) / cellSize), maxX = Int((p.x + radius) / cellSize)
        let minY = Int((p.y - radius) / cellSize), maxY = Int((p.y + radius) / cellSize)
        guard minX <= maxX, minY <= maxY else { return }
        for y in minY...maxY {
            for x in minX...maxX where center(x, y).distance(to: p) <= radius {
                set(x, y, rock: false)
            }
        }
    }

    /// Opens every cell whose centre lies in `rect` grown by `margin`.
    mutating func carve(_ rect: CGRect, margin: CGFloat = 0) {
        let r = rect.insetBy(dx: -margin, dy: -margin)
        for y in 0..<rows {
            for x in 0..<columns where r.contains(center(x, y)) { set(x, y, rock: false) }
        }
    }

    /// Merges rock cells into as few rectangles as possible (row runs stacked vertically).
    func rectangles() -> [CGRect] {
        var result: [CGRect] = []
        var open: [Run: Int] = [:]
        for y in 0...rows {
            var runs: [Run] = []
            if y < rows {
                var x = 0
                while x < columns {
                    if isRock(x, y) {
                        let start = x
                        while x < columns && isRock(x, y) { x += 1 }
                        runs.append(Run(start: start, end: x))
                    } else {
                        x += 1
                    }
                }
            }
            var next: [Run: Int] = [:]
            for run in runs { next[run] = open[run] ?? y }
            for (run, startRow) in open where next[run] == nil {
                result.append(CGRect(x: CGFloat(run.start) * cellSize, y: CGFloat(startRow) * cellSize,
                                     width: CGFloat(run.end - run.start) * cellSize,
                                     height: CGFloat(y - startRow) * cellSize))
            }
            open = next
        }
        return result
    }

    private struct Run: Hashable {
        let start: Int
        let end: Int
    }
}
