import CoreGraphics

/// Result of tracing one bullet.
struct BulletHit {
    let point: CGPoint
    let soldierId: Int?
    let vehicleId: Int?
    let blockedByWall: Bool
}

/// Hitscan tracing against walls, enemy soldiers (not those inside vehicles) and enemy vehicles.
@MainActor
enum Ballistics {
    static func trace(from start: CGPoint, to end: CGPoint, shooter: Soldier, world: BattleWorld,
                      ignoreWalls: Bool = false) -> BulletHit {
        let wallT = ignoreWalls ? nil : world.map.raycast(from: start, to: end)
        var bestT = wallT ?? 1
        var victimId: Int?
        var vehicleId: Int?
        for soldier in world.soldiers where soldier.isAlive && !soldier.isMounted && soldier.team != shooter.team {
            if let t = rayCircle(start, end, center: soldier.position, radius: soldier.radius), t < bestT {
                bestT = t
                victimId = soldier.id
                vehicleId = nil
            }
        }
        for vehicle in world.vehicles where vehicle.isAlive && vehicle.team != shooter.team {
            if let t = rayCircle(start, end, center: vehicle.position, radius: vehicle.radius), t < bestT {
                bestT = t
                vehicleId = vehicle.id
                victimId = nil
            }
        }
        let point = start.lerp(to: end, t: bestT)
        let blocked = victimId == nil && vehicleId == nil && wallT != nil
        return BulletHit(point: point, soldierId: victimId, vehicleId: vehicleId, blockedByWall: blocked)
    }

    /// Fraction along start-end where the segment first touches the circle.
    static func rayCircle(_ start: CGPoint, _ end: CGPoint, center: CGPoint, radius: CGFloat) -> CGFloat? {
        let d = end - start
        let f = start - center
        let a = d.dot(d)
        guard a > 0.0001 else { return nil }
        let b = 2 * f.dot(d)
        let c = f.dot(f) - radius * radius
        let discriminant = b * b - 4 * a * c
        guard discriminant >= 0 else { return nil }
        let t = (-b - discriminant.squareRoot()) / (2 * a)
        return t >= 0 && t <= 1 ? t : nil
    }
}
