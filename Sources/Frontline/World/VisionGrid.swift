import CoreGraphics

/// Low-resolution visibility grid for one team (true = currently visible).
struct VisionGrid {
    let cellSize: CGFloat
    let columns: Int
    private(set) var cells: [Bool]

    init(worldSize: CGFloat, cellSize: CGFloat) {
        let count = Int((worldSize / cellSize).rounded(.up))
        self.cellSize = cellSize
        self.columns = count
        self.cells = Array(repeating: false, count: count * count)
    }

    mutating func clear() {
        for i in cells.indices { cells[i] = false }
    }

    mutating func reveal(center: CGPoint, radius: CGFloat) {
        let minX = coord(center.x - radius), maxX = coord(center.x + radius)
        let minY = coord(center.y - radius), maxY = coord(center.y + radius)
        let rSq = radius * radius
        for cy in minY...maxY {
            let py = (CGFloat(cy) + 0.5) * cellSize - center.y
            for cx in minX...maxX {
                let px = (CGFloat(cx) + 0.5) * cellSize - center.x
                if px * px + py * py <= rSq {
                    cells[cy * columns + cx] = true
                }
            }
        }
    }

    func isVisible(_ p: CGPoint) -> Bool {
        cells[coord(p.y) * columns + coord(p.x)]
    }

    func isVisible(column: Int, row: Int) -> Bool {
        cells[row * columns + column]
    }

    private func coord(_ v: CGFloat) -> Int {
        Swift.min(Swift.max(Int(v / cellSize), 0), columns - 1)
    }
}
