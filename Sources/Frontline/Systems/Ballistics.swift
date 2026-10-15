import CoreGraphics

/// Result of tracing one bullet.
struct BulletHit {
    let point: CGPoint
    let soldierId: Int?
    let blockedByWall: Bool
}

/// Hitscan bullet tracing against walls and enemy soldiers.
@MainActor
enum Ballistics {
    static func trace(from start: CGPoint, to end: CGPoint, shooter: Soldier, world: BattleWorld) -> BulletHit {
        let wallT = world.map.raycast(from: start, to: end)
        var bestT = wallT ?? 1
        var victimId: Int?
        for soldier in world.soldiers where soldier.isAlive && soldier.team != shooter.team {
            if let t = rayCircle(start, end, center: soldier.position, radius: soldier.radius), t < bestT {
                bestT = t
                victimId = soldier.id
            }
        }
        let point = start.lerp(to: end, t: bestT)
        return BulletHit(point: point, soldierId: victimId, blockedByWall: victimId == nil && wallT != nil)
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
