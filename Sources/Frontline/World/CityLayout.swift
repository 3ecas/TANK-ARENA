import CoreGraphics

/// One building footprint (solid obstacle).
struct CityBuilding {
    let rect: CGRect
    /// Visual variant (roof colour / details).
    let style: Int
}

/// The city blocks between the lanes: buildings (obstacles) and parks (walkable).
/// Buildings are bucketed for fast collision queries.
struct CityLayout {
    let buildings: [CityBuilding]
    let parks: [CGRect]
    private let bucketSize: CGFloat = 250
    private let columns: Int
    private let buckets: [[Int]]

    init(buildings: [CityBuilding], parks: [CGRect], worldSize: CGFloat) {
        self.buildings = buildings
        self.parks = parks
        let count = Int((worldSize / 250).rounded(.up)) + 1
        columns = count
        var grid = Array(repeating: [Int](), count: count * count)
        for (index, building) in buildings.enumerated() {
            let r = building.rect
            let minX = CityLayout.coord(r.minX, count), maxX = CityLayout.coord(r.maxX, count)
            let minY = CityLayout.coord(r.minY, count), maxY = CityLayout.coord(r.maxY, count)
            for y in minY...maxY {
                for x in minX...maxX { grid[y * count + x].append(index) }
            }
        }
        buckets = grid
    }

    /// Buildings whose footprint may touch the circle.
    func buildings(near point: CGPoint, radius: CGFloat) -> [CityBuilding] {
        let minX = CityLayout.coord(point.x - radius, columns), maxX = CityLayout.coord(point.x + radius, columns)
        let minY = CityLayout.coord(point.y - radius, columns), maxY = CityLayout.coord(point.y + radius, columns)
        var seen = Set<Int>()
        var result: [CityBuilding] = []
        for y in minY...maxY {
            for x in minX...maxX {
                for index in buckets[y * columns + x] where !seen.contains(index) {
                    seen.insert(index)
                    if buildings[index].rect.insetBy(dx: -radius, dy: -radius).contains(point) {
                        result.append(buildings[index])
                    }
                }
            }
        }
        return result
    }

    private static func coord(_ value: CGFloat, _ count: Int) -> Int {
        Swift.min(Swift.max(Int(value / 250), 0), count - 1)
    }
}
