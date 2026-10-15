import CoreGraphics

enum ProjectileKind {
    case bullet, rocket, shell, grenade, cannon
}

/// A travelling shot. Homing when it has a target; otherwise flies to a point (grenades).
@MainActor
final class Projectile {
    let id: Int
    let team: Team
    let sourceId: Int
    let kind: ProjectileKind
    let targetId: Int?
    let speed: CGFloat
    let damage: CGFloat
    let splashRadius: CGFloat
    let vsArmored: CGFloat
    var position: CGPoint
    var targetPoint: CGPoint
    var isDone = false

    init(id: Int, team: Team, sourceId: Int, kind: ProjectileKind, from: CGPoint, targetId: Int?,
         targetPoint: CGPoint, speed: CGFloat, damage: CGFloat, splashRadius: CGFloat, vsArmored: CGFloat) {
        self.id = id
        self.team = team
        self.sourceId = sourceId
        self.kind = kind
        self.position = from
        self.targetId = targetId
        self.targetPoint = targetPoint
        self.speed = speed
        self.damage = damage
        self.splashRadius = splashRadius
        self.vsArmored = vsArmored
    }

    var angle: CGFloat { (targetPoint - position).angle }
}
