import CoreGraphics

/// Uniform grid rebuilt every frame for fast neighbour queries (targeting, collision).
@MainActor
final class SpatialGrid {
    let cellSize: CGFloat
    let columns: Int
    private var cells: [[Entity]]
    /// Extra search padding so large entities (structures) near a cell border are found.
    private let padding: CGFloat = 90

    init(worldSize: CGFloat, cellSize: CGFloat) {
        let count = Int((worldSize / cellSize).rounded(.up)) + 1
        self.cellSize = cellSize
        self.columns = count
        self.cells = Array(repeating: [], count: count * count)
    }

    func rebuild(with entities: [Entity]) {
        for i in cells.indices {
            cells[i].removeAll(keepingCapacity: true)
        }
        for entity in entities where entity.isAlive && !entity.isRemoved {
            cells[index(for: entity.position)].append(entity)
        }
    }

    /// All live entities whose body overlaps the circle.
    func query(center: CGPoint, radius: CGFloat) -> [Entity] {
        var result: [Entity] = []
        let reach = radius + padding
        let minX = cellCoord(center.x - reach), maxX = cellCoord(center.x + reach)
        let minY = cellCoord(center.y - reach), maxY = cellCoord(center.y + reach)
        for cy in minY...maxY {
            for cx in minX...maxX {
                for entity in cells[cy * columns + cx] {
                    let r = radius + entity.radius
                    if entity.position.distanceSquared(to: center) <= r * r {
                        result.append(entity)
                    }
                }
            }
        }
        return result
    }

    private func cellCoord(_ value: CGFloat) -> Int {
        Swift.min(Swift.max(Int(value / cellSize), 0), columns - 1)
    }

    private func index(for p: CGPoint) -> Int {
        cellCoord(p.y) * columns + cellCoord(p.x)
    }
}
