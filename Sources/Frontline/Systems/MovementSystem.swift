import CoreGraphics

/// Walking, turning, and collisions with walls and other soldiers.
@MainActor
final class MovementSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        let bounds = world.map.bounds.insetBy(dx: GameConfig.soldierRadius, dy: GameConfig.soldierRadius)
        let alive = world.soldiers.filter { $0.isAlive }
        for soldier in alive {
            var speed = GameConfig.walkSpeed * soldier.activeWeapon.def.speedMultiplier
            if soldier.isStunned { speed *= 1 - GrenadeConfig.stunSlow }
            soldier.velocity = soldier.moveDir.clampedLength(1) * speed
            soldier.position = (soldier.position + soldier.velocity * dt).clamped(to: bounds)
            turn(soldier, dt: dt)
            let reach = soldier.radius + 2
            let area = CGRect(x: soldier.position.x - reach, y: soldier.position.y - reach, width: reach * 2, height: reach * 2)
            for obstacle in world.map.obstacles(near: area) {
                push(soldier, outOf: obstacle.rect)
            }
        }
        separate(alive)
    }

    /// The player faces the cursor instantly; bots turn at a limited rate.
    private func turn(_ soldier: Soldier, dt: CGFloat) {
        let delta = soldier.aimPoint - soldier.position
        guard delta.lengthSquared > 1 else { return }
        let desired = delta.angle
        soldier.facing = soldier.isPlayer
            ? desired
            : Angle.approach(soldier.facing, desired, maxStep: AIConfig.turnRate * dt)
    }

    private func separate(_ soldiers: [Soldier]) {
        for i in 0..<soldiers.count {
            for j in (i + 1)..<soldiers.count {
                let a = soldiers[i], b = soldiers[j]
                let delta = a.position - b.position
                let minDistance = a.radius + b.radius
                let distSq = delta.lengthSquared
                guard distSq < minDistance * minDistance, distSq > 0.0001 else { continue }
                let dist = distSq.squareRoot()
                let offset = delta / dist * ((minDistance - dist) * 0.5)
                a.position += offset
                b.position -= offset
            }
        }
    }

    /// Pushes a soldier out of an axis-aligned obstacle.
    private func push(_ soldier: Soldier, outOf rect: CGRect) {
        let p = soldier.position
        let r = soldier.radius
        guard rect.insetBy(dx: -r, dy: -r).contains(p) else { return }
        if rect.contains(p) {
            let left = p.x - rect.minX, right = rect.maxX - p.x
            let bottom = p.y - rect.minY, top = rect.maxY - p.y
            let smallest = Swift.min(left, right, bottom, top)
            if smallest == left {
                soldier.position.x = rect.minX - r
            } else if smallest == right {
                soldier.position.x = rect.maxX + r
            } else if smallest == bottom {
                soldier.position.y = rect.minY - r
            } else {
                soldier.position.y = rect.maxY + r
            }
            return
        }
        let closest = CGPoint(x: p.x.clamped(rect.minX, rect.maxX), y: p.y.clamped(rect.minY, rect.maxY))
        let delta = p - closest
        let distance = delta.length
        if distance < r && distance > 0.001 {
            soldier.position = closest + delta * (r / distance)
        }
    }
}
