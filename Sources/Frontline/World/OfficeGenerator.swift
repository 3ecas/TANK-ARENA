import CoreGraphics

/// Generates an irregular office floor by recursive division: each area is split by a wall at a random
/// position (never through a spawn, a bomb site or an existing doorway), and every wall gets one or two
/// doorways, so every room stays reachable. Rooms get a few desks as cover. Nothing is mirrored.
struct OfficeGenerator {
    let style: OfficeStyle
    var size: CGSize { style.size }
    var spawns: [CGRect] { [style.attackerSpawn, style.defenderSpawn] }
    private(set) var sites: [ZoneConfig.ZoneSpec] = []
    private var rng: SeededRandom
    private var walls: [CGRect] = []
    private var doors: [CGRect] = []
    private var rooms: [CGRect] = []
    private var protected: [CGRect] = []

    init(seed: UInt64, style: OfficeStyle) {
        self.style = style
        rng = SeededRandom(seed: seed)
    }

    mutating func generate() -> [Obstacle] {
        var placedSites: [ZoneConfig.ZoneSpec] = []
        for spec in style.siteAreas {
            let x = spec.area.minX + rng.next() * spec.area.width
            let y = spec.area.minY + rng.next() * spec.area.height
            placedSites.append(ZoneConfig.ZoneSpec(name: spec.name, center: CGPoint(x: x, y: y)))
        }
        sites = placedSites
        protected = spawns.map { $0.insetBy(dx: -40, dy: -40) }
            + sites.map { CGRect(x: $0.center.x - 180, y: $0.center.y - 180, width: 360, height: 360) }
        let o = OfficeConfig.outerWall
        walls = [CGRect(x: 0, y: 0, width: size.width, height: o),
                 CGRect(x: 0, y: size.height - o, width: size.width, height: o),
                 CGRect(x: 0, y: 0, width: o, height: size.height),
                 CGRect(x: size.width - o, y: 0, width: o, height: size.height)]
        divide(CGRect(x: o, y: o, width: size.width - 2 * o, height: size.height - 2 * o), depth: 0)
        let solid = walls.filter { $0.width > 0.5 && $0.height > 0.5 }
        return solid.map { Obstacle(rect: $0, kind: .wall) } + placeDesks().map { Obstacle(rect: $0, kind: .desk) }
    }

    private mutating func divide(_ rect: CGRect, depth: Int) {
        if depth > 0 && rect.width * rect.height < style.stopArea && rng.next() < style.stopChance {
            rooms.append(rect)
            return
        }
        var orientations = rect.width > rect.height ? [true, false] : [false, true]
        if rng.next() < 0.3 { orientations.reverse() }
        for vertical in orientations {
            let options = splitOptions(rect, vertical: vertical)
            guard !options.isEmpty else { continue }
            let at = options[Swift.min(options.count - 1, Int(rng.next() * CGFloat(options.count)))]
            buildWall(in: rect, at: at, vertical: vertical)
            if vertical {
                divide(CGRect(x: rect.minX, y: rect.minY, width: at - rect.minX, height: rect.height), depth: depth + 1)
                divide(CGRect(x: at, y: rect.minY, width: rect.maxX - at, height: rect.height), depth: depth + 1)
            } else {
                divide(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: at - rect.minY), depth: depth + 1)
                divide(CGRect(x: rect.minX, y: at, width: rect.width, height: rect.maxY - at), depth: depth + 1)
            }
            return
        }
        rooms.append(rect)
    }

    /// Wall positions (every 20 points) that keep both rooms big enough and cross no spawn, site or doorway.
    private func splitOptions(_ rect: CGRect, vertical: Bool) -> [CGFloat] {
        let t = OfficeConfig.wallThickness, minRoom = style.minRoom
        let low = (vertical ? rect.minX : rect.minY) + minRoom
        let high = (vertical ? rect.maxX : rect.maxY) - minRoom
        guard low <= high else { return [] }
        return stride(from: low, through: high, by: 20).filter { at in
            let line = vertical ? CGRect(x: at - t / 2, y: rect.minY, width: t, height: rect.height)
                                : CGRect(x: rect.minX, y: at - t / 2, width: rect.width, height: t)
            let clearance = line.insetBy(dx: vertical ? -30 : 0, dy: vertical ? 0 : -30)
            return !protected.contains { $0.intersects(line) } && !doors.contains { $0.intersects(clearance) }
        }
    }

    /// A wall across `rect` with one doorway (more on long walls).
    private mutating func buildWall(in rect: CGRect, at: CGFloat, vertical: Bool) {
        let t = OfficeConfig.wallThickness, door = style.doorWidth
        let start = vertical ? rect.minY : rect.minX
        let span = vertical ? rect.height : rect.width
        let count = span > style.doorSpan * 2 ? 3 : (span > style.doorSpan ? 2 : 1)
        var gaps: [CGFloat] = []
        for _ in 0..<count { gaps.append(start + 40 + rng.next() * (span - 80 - door)) }
        var position = start
        for gap in gaps.sorted() where gap >= position {
            addPiece(from: position, to: gap, at: at, vertical: vertical, thickness: t)
            doors.append(vertical ? CGRect(x: at - t / 2, y: gap, width: t, height: door)
                                  : CGRect(x: gap, y: at - t / 2, width: door, height: t))
            position = gap + door
        }
        addPiece(from: position, to: start + span, at: at, vertical: vertical, thickness: t)
    }

    private mutating func addPiece(from a: CGFloat, to b: CGFloat, at: CGFloat, vertical: Bool, thickness t: CGFloat) {
        guard b > a else { return }
        walls.append(vertical ? CGRect(x: at - t / 2, y: a, width: t, height: b - a)
                              : CGRect(x: a, y: at - t / 2, width: b - a, height: t))
    }

    /// A few desks per room (bigger rooms get more), clear of the walls, spawns and site centres.
    private mutating func placeDesks() -> [CGRect] {
        var result: [CGRect] = []
        let margin = OfficeConfig.deskMargin
        for room in rooms {
            let area = room.insetBy(dx: margin, dy: margin)
            guard area.width >= 60, area.height >= 60,
                  !spawns.contains(where: { $0.insetBy(dx: -40, dy: -40).intersects(area) }) else { continue }
            let count = Swift.min(style.maxDesks, Int(rng.next() * CGFloat(style.maxDesks)) + (room.width * room.height > 300 * 300 ? 1 : 0))
            var placed: [CGRect] = []
            for _ in 0..<(count * 6) where placed.count < count {
                let sizes = OfficeConfig.deskSizes
                let deskSize = sizes[Swift.min(sizes.count - 1, Int(rng.next() * CGFloat(sizes.count)))]
                guard area.width >= deskSize.width, area.height >= deskSize.height else { continue }
                let desk = CGRect(x: area.minX + rng.next() * (area.width - deskSize.width),
                                  y: area.minY + rng.next() * (area.height - deskSize.height),
                                  width: deskSize.width, height: deskSize.height)
                let clearOfSites = sites.allSatisfy { CGPoint(x: desk.midX, y: desk.midY).distance(to: $0.center) > 70 }
                let clearOfDesks = placed.allSatisfy { !$0.insetBy(dx: -60, dy: -60).intersects(desk) }
                if clearOfSites && clearOfDesks { placed.append(desk) }
            }
            result += placed
        }
        return result
    }
}
