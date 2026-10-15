import CoreGraphics

/// Buckets obstacles on a coarse grid so collision, line-of-sight and bullet tests only
/// look at the obstacles near the area they cover (the cave map has hundreds of rock blocks).
struct ObstacleIndex {
    private let bucketSize: CGFloat = 200
    private let columns: Int
    private let rows: Int
    private var buckets: [[Int]]

    init(obstacles: [Obstacle], size: CGSize) {
        columns = Swift.max(1, Int((size.width / bucketSize).rounded(.up)))
        rows = Swift.max(1, Int((size.height / bucketSize).rounded(.up)))
        var lists = [[Int]](repeating: [], count: columns * rows)
        for (index, obstacle) in obstacles.enumerated() {
            let (x0, y0, x1, y1) = ObstacleIndex.range(obstacle.rect, bucketSize, columns, rows)
            for y in y0...y1 {
                for x in x0...x1 { lists[y * columns + x].append(index) }
            }
        }
        buckets = lists
    }

    /// Indices of obstacles that may overlap `rect` (an obstacle spanning several buckets can repeat).
    func candidates(in rect: CGRect) -> [Int] {
        let (x0, y0, x1, y1) = ObstacleIndex.range(rect, bucketSize, columns, rows)
        if x0 == x1 && y0 == y1 { return buckets[y0 * columns + x0] }
        var result: [Int] = []
        for y in y0...y1 {
            for x in x0...x1 { result += buckets[y * columns + x] }
        }
        return result
    }

    private static func range(_ rect: CGRect, _ size: CGFloat, _ columns: Int, _ rows: Int) -> (Int, Int, Int, Int) {
        func clampX(_ v: CGFloat) -> Int { Swift.min(columns - 1, Swift.max(0, Int(floor(v / size)))) }
        func clampY(_ v: CGFloat) -> Int { Swift.min(rows - 1, Swift.max(0, Int(floor(v / size)))) }
        return (clampX(rect.minX), clampY(rect.minY), clampX(rect.maxX), clampY(rect.maxY))
    }
}
