import CoreGraphics

/// A doorway, room entrance or passage mouth that bots watch, stack up on and clear.
struct Chokepoint {
    let position: CGPoint
    /// Unit vector pointing through the opening (from one side to the other).
    let axis: CGPoint
}

/// Finds the doorways and entrances of any map once, by probing the open floor: a spot is an entrance when
/// it is narrow across (walls close on both sides) but opens into a wide area a little further along.
/// Only walls and rock count — gaps between crates or desks are cover, not doorways.
@MainActor
final class Chokepoints {
    private(set) var points: [Chokepoint] = []

    init(map: ArenaMap) {
        let structure = map.obstacles.filter { $0.kind == .wall || $0.kind == .rock || $0.kind == .building }
        let walls = Walls(obstacles: structure, size: map.size)
        var found: [(CGPoint, CGPoint)] = []
        let step = AIConfig.chokeProbeStep
        var y = step / 2
        while y < map.size.height {
            var x = step / 2
            while x < map.size.width {
                let p = CGPoint(x: x, y: y)
                if !map.isInsideObstacle(p, padding: GameConfig.soldierRadius),
                   let axis = Chokepoints.openingAxis(at: p, walls: walls) {
                    found.append((p, axis))
                }
                x += step
            }
            y += step
        }
        points = Chokepoints.cluster(found)
    }

    /// Structural obstacles only, with their own spatial index.
    private struct Walls {
        let rects: [CGRect]
        let index: ObstacleIndex

        init(obstacles: [Obstacle], size: CGSize) {
            rects = obstacles.map { $0.rect }
            index = ObstacleIndex(obstacles: obstacles, size: size)
        }

        /// Free distance from `p` in a direction, up to `limit`.
        func reach(_ p: CGPoint, _ direction: CGPoint, _ limit: CGFloat) -> CGFloat {
            let end = p + direction * limit
            let box = CGRect(x: Swift.min(p.x, end.x), y: Swift.min(p.y, end.y), width: abs(end.x - p.x), height: abs(end.y - p.y))
            var best: CGFloat = 1
            for i in index.candidates(in: box) {
                if let t = ArenaMap.segmentHit(p, end, rects[i]), t < best { best = t }
            }
            return best * limit
        }
    }

    /// Passage direction if `p` sits in an opening, nil otherwise.
    private static func openingAxis(at p: CGPoint, walls: Walls) -> CGPoint? {
        let narrow = AIConfig.chokeMaxWidth, wide = AIConfig.chokeOpenWidth, look = AIConfig.chokeLookAhead
        for axis in [CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1)] {
            let across = axis.perpendicular
            let width = walls.reach(p, across, narrow) + walls.reach(p, across * -1, narrow)
            guard width < narrow,
                  walls.reach(p, axis, look) >= look, walls.reach(p, axis * -1, look) >= look else { continue }
            // Wide on at least one side: a door between rooms or the mouth of a corridor.
            let ahead = p + axis * look, behind = p - axis * look
            let aheadWidth = walls.reach(ahead, across, wide) + walls.reach(ahead, across * -1, wide)
            let behindWidth = walls.reach(behind, across, wide) + walls.reach(behind, across * -1, wide)
            if Swift.max(aheadWidth, behindWidth) >= wide { return axis }
        }
        return nil
    }

    /// Merges nearby probe hits into one point per opening.
    private static func cluster(_ hits: [(CGPoint, CGPoint)]) -> [Chokepoint] {
        var groups: [(sum: CGPoint, count: Int, axis: CGPoint)] = []
        for (point, axis) in hits {
            if let index = groups.firstIndex(where: { ($0.sum / CGFloat($0.count)).distance(to: point) < AIConfig.chokeMergeRadius }) {
                groups[index].sum = groups[index].sum + point
                groups[index].count += 1
            } else {
                groups.append((point, 1, axis))
            }
        }
        return groups.map { Chokepoint(position: $0.sum / CGFloat($0.count), axis: $0.axis) }
    }

    /// Openings within `range` that `origin` has a clear line of sight to.
    func visible(from origin: CGPoint, within range: CGFloat, map: ArenaMap) -> [Chokepoint] {
        points.filter { $0.position.distance(to: origin) <= range && map.hasLineOfSight(origin, $0.position) }
    }
}
