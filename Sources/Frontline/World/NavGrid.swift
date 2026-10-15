import CoreGraphics

/// Walkability grid for click-to-move pathfinding (A* with line-of-sight smoothing).
/// Obstacles are city buildings and structures, padded by the size of a soldier.
struct NavGrid {
    let cellSize: CGFloat
    let columns: Int
    private var blocked: [Bool]
    /// Upper bound on A* expansions so a bad request can never stall a frame.
    private let maxExpansions = 20000

    init(worldSize: CGFloat, cellSize: CGFloat) {
        let count = Int((worldSize / cellSize).rounded(.up))
        self.cellSize = cellSize
        self.columns = count
        self.blocked = Array(repeating: false, count: count * count)
    }

    /// Marks every cell overlapping a (padded) rectangle or circle as blocked.
    mutating func rebuild(rects: [CGRect], circles: [(CGPoint, CGFloat)], padding: CGFloat) {
        for i in blocked.indices { blocked[i] = false }
        for rect in rects {
            let r = rect.insetBy(dx: -padding, dy: -padding)
            for (cell, center) in cells(in: r) where r.contains(center) { blocked[cell] = true }
        }
        for (center, radius) in circles {
            let r = radius + padding
            let box = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            for (cell, cellCenter) in cells(in: box) where cellCenter.distance(to: center) <= r { blocked[cell] = true }
        }
    }

    func isBlocked(_ p: CGPoint) -> Bool {
        blocked[index(of: p)]
    }

    /// True when the straight segment a-b crosses no blocked cell.
    func hasLineOfSight(_ a: CGPoint, _ b: CGPoint) -> Bool {
        let distance = a.distance(to: b)
        let steps = Swift.max(1, Int(distance / (cellSize * 0.4)))
        for s in 0...steps where isBlocked(a.lerp(to: b, t: CGFloat(s) / CGFloat(steps))) {
            return false
        }
        return true
    }

    /// Nearest walkable point to `p` (p itself if already walkable).
    func nearestWalkable(_ p: CGPoint) -> CGPoint {
        let start = index(of: p)
        if !blocked[start] { return p }
        guard let free = nearestFree(start) else { return p }
        return center(free)
    }

    /// Smoothed list of waypoints from `start` to `goal`, or nil when unreachable.
    func findPath(from start: CGPoint, to goal: CGPoint) -> [CGPoint]? {
        let target = nearestWalkable(goal)
        if hasLineOfSight(start, target) { return [target] }
        var startIndex = index(of: start)
        if blocked[startIndex], let free = nearestFree(startIndex) { startIndex = free }
        let goalIndex = index(of: target)
        guard !blocked[goalIndex] else { return nil }

        let total = columns * columns
        var gScore = [Float](repeating: .greatestFiniteMagnitude, count: total)
        var cameFrom = [Int32](repeating: -1, count: total)
        var closed = [Bool](repeating: false, count: total)
        var frontier = BinaryHeap()
        gScore[startIndex] = 0
        frontier.push(heuristic(startIndex, goalIndex), Int32(startIndex))
        var expansions = 0

        while let currentRaw = frontier.pop() {
            let current = Int(currentRaw)
            if current == goalIndex { break }
            if closed[current] { continue }
            closed[current] = true
            expansions += 1
            if expansions > maxExpansions { return nil }
            let cx = current % columns, cy = current / columns
            for dy in -1...1 {
                for dx in -1...1 where dx != 0 || dy != 0 {
                    let nx = cx + dx, ny = cy + dy
                    guard nx >= 0, ny >= 0, nx < columns, ny < columns else { continue }
                    let next = ny * columns + nx
                    if blocked[next] || closed[next] { continue }
                    // No corner cutting past buildings.
                    if dx != 0 && dy != 0 && (blocked[cy * columns + nx] || blocked[ny * columns + cx]) { continue }
                    let cost: Float = (dx != 0 && dy != 0) ? 1.4142 : 1
                    let tentative = gScore[current] + cost
                    if tentative < gScore[next] {
                        gScore[next] = tentative
                        cameFrom[next] = Int32(current)
                        frontier.push(tentative + heuristic(next, goalIndex), Int32(next))
                    }
                }
            }
        }
        guard cameFrom[goalIndex] >= 0 || goalIndex == startIndex else { return nil }

        var cells: [CGPoint] = [target]
        var node = Int(cameFrom[goalIndex])
        while node >= 0 && node != startIndex {
            cells.append(center(node))
            node = Int(cameFrom[node])
        }
        cells.reverse()
        return smooth(cells, from: start)
    }

    // MARK: Helpers

    private func smooth(_ points: [CGPoint], from start: CGPoint) -> [CGPoint] {
        var result: [CGPoint] = []
        var anchor = start
        var i = 0
        while i < points.count {
            var j = points.count - 1
            while j > i && !hasLineOfSight(anchor, points[j]) { j -= 1 }
            result.append(points[j])
            anchor = points[j]
            i = j + 1
        }
        return result
    }

    private func heuristic(_ a: Int, _ b: Int) -> Float {
        let dx = Float(abs(a % columns - b % columns)), dy = Float(abs(a / columns - b / columns))
        return Swift.max(dx, dy) + 0.4142 * Swift.min(dx, dy)
    }

    private func nearestFree(_ start: Int) -> Int? {
        let sx = start % columns, sy = start / columns
        for radius in 1...12 {
            var best: Int?
            var bestDistance = Int.max
            for dy in -radius...radius {
                for dx in -radius...radius where abs(dx) == radius || abs(dy) == radius {
                    let x = sx + dx, y = sy + dy
                    guard x >= 0, y >= 0, x < columns, y < columns, !blocked[y * columns + x] else { continue }
                    let d = dx * dx + dy * dy
                    if d < bestDistance { bestDistance = d; best = y * columns + x }
                }
            }
            if let best = best { return best }
        }
        return nil
    }

    private func index(of p: CGPoint) -> Int {
        coord(p.y) * columns + coord(p.x)
    }

    private func coord(_ v: CGFloat) -> Int {
        Swift.min(Swift.max(Int(v / cellSize), 0), columns - 1)
    }

    private func center(_ index: Int) -> CGPoint {
        CGPoint(x: (CGFloat(index % columns) + 0.5) * cellSize, y: (CGFloat(index / columns) + 0.5) * cellSize)
    }

    /// Cell indices and centres overlapping a rectangle.
    private func cells(in rect: CGRect) -> [(Int, CGPoint)] {
        let minX = coord(rect.minX), maxX = coord(rect.maxX)
        let minY = coord(rect.minY), maxY = coord(rect.maxY)
        var result: [(Int, CGPoint)] = []
        for y in minY...maxY {
            for x in minX...maxX {
                result.append((y * columns + x, CGPoint(x: (CGFloat(x) + 0.5) * cellSize, y: (CGFloat(y) + 0.5) * cellSize)))
            }
        }
        return result
    }
}
