import CoreGraphics

/// Lays out city blocks on a grid, keeping lanes, the river, bases and objectives clear.
enum CityGenerator {
    static func generate(map: MapLayout) -> CityLayout {
        var rng = SeededRandom(seed: CityConfig.seed)
        var buildings: [CityBuilding] = []
        var parks: [CGRect] = []
        let pitch = CityConfig.blockPitch
        let blockSize = pitch - CityConfig.streetWidth
        let count = Int(map.size / pitch)
        // Centre the grid so the city is point-symmetric (fair for both teams).
        let offset = (map.size - CGFloat(count) * pitch) / 2
        let laneSamples = Lane.allCases.map { samples(along: map.path($0, for: .blue).points) }
        let riverSamples = samples(along: [map.riverStart, map.riverEnd])

        for by in 0..<count {
            for bx in 0..<count {
                let block = CGRect(x: offset + CGFloat(bx) * pitch + CityConfig.streetWidth / 2,
                                   y: offset + CGFloat(by) * pitch + CityConfig.streetWidth / 2,
                                   width: blockSize, height: blockSize)
                guard isClear(block, map: map, lanes: laneSamples, river: riverSamples) else { continue }
                if rng.next() < CityConfig.parkChance {
                    parks.append(block)
                } else {
                    buildings += split(block, rng: &rng)
                }
            }
        }
        return CityLayout(buildings: buildings, parks: parks, worldSize: map.size)
    }

    /// Divides a block into 1, 2 or 4 buildings.
    private static func split(_ block: CGRect, rng: inout SeededRandom) -> [CityBuilding] {
        let gap = CityConfig.buildingGap
        let inner = block.insetBy(dx: 8, dy: 8)
        let roll = rng.next()
        var rects: [CGRect] = []
        if roll < 0.3 {
            rects = [inner.insetBy(dx: rng.next() * 14, dy: rng.next() * 14)]
        } else if roll < 0.65 {
            let vertical = rng.next() < 0.5
            let t = 0.35 + rng.next() * 0.3
            if vertical {
                let w = inner.width * t
                rects = [CGRect(x: inner.minX, y: inner.minY, width: w - gap / 2, height: inner.height),
                         CGRect(x: inner.minX + w + gap / 2, y: inner.minY, width: inner.width - w - gap / 2,
                                height: inner.height)]
            } else {
                let h = inner.height * t
                rects = [CGRect(x: inner.minX, y: inner.minY, width: inner.width, height: h - gap / 2),
                         CGRect(x: inner.minX, y: inner.minY + h + gap / 2, width: inner.width,
                                height: inner.height - h - gap / 2)]
            }
        } else {
            let w = (inner.width - gap) / 2, h = (inner.height - gap) / 2
            for i in 0..<4 {
                let x = inner.minX + CGFloat(i % 2) * (w + gap)
                let y = inner.minY + CGFloat(i / 2) * (h + gap)
                // Sometimes leave a courtyard / parking lot empty.
                if rng.next() < 0.15 { continue }
                rects.append(CGRect(x: x, y: y, width: w, height: h))
            }
        }
        return rects.map { CityBuilding(rect: $0, style: Int(rng.next() * 6)) }
    }

    private static func isClear(_ block: CGRect, map: MapLayout, lanes: [[CGPoint]], river: [CGPoint]) -> Bool {
        let edge = CityConfig.mapEdgeMargin
        guard block.minX > edge, block.minY > edge, block.maxX < map.size - edge, block.maxY < map.size - edge else {
            return false
        }
        let laneLimit = MapConfig.laneWidth / 2 + CityConfig.laneClearance
        for lane in lanes where lane.contains(where: { distance(from: $0, to: block) < laneLimit }) { return false }
        let riverLimit = MapConfig.riverWidth / 2 + CityConfig.riverClearance
        if river.contains(where: { distance(from: $0, to: block) < riverLimit }) { return false }
        let baseLimit = MapConfig.baseRadius + CityConfig.baseClearance
        if Team.playable.contains(where: { distance(from: map.spawnPoint($0), to: block) < baseLimit }) { return false }
        let objectives = ObjectiveConfig.campPositions
            + [ObjectiveConfig.radarPosition, ObjectiveConfig.airfieldPosition, ObjectiveConfig.depotPosition]
        if objectives.contains(where: { distance(from: $0, to: block) < CityConfig.objectiveClearance }) { return false }
        return true
    }

    /// Points every 40pt along a polyline.
    private static func samples(along points: [CGPoint]) -> [CGPoint] {
        var result: [CGPoint] = []
        for i in 0..<(points.count - 1) {
            let a = points[i], b = points[i + 1]
            let steps = Swift.max(1, Int(a.distance(to: b) / 40))
            for s in 0...steps { result.append(a.lerp(to: b, t: CGFloat(s) / CGFloat(steps))) }
        }
        return result
    }

    private static func distance(from p: CGPoint, to rect: CGRect) -> CGFloat {
        let closest = CGPoint(x: p.x.clamped(rect.minX, rect.maxX), y: p.y.clamped(rect.minY, rect.maxY))
        return p.distance(to: closest)
    }
}
