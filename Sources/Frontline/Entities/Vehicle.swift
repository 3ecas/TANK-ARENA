import CoreGraphics

/// A tank or helicopter, driven by the soldier who called it in (its pilot rides inside).
@MainActor
final class Vehicle {
    let id: Int
    let kind: VehicleKind
    let team: Team
    var position: CGPoint
    /// Hull direction (tank) / body direction (helicopter).
    var facing: CGFloat
    /// Turret / gun direction.
    var aim: CGFloat
    var hp: CGFloat
    var pilotId: Int?
    var cooldown: CGFloat = 0
    /// Seconds left before a helicopter leaves.
    var timeLeft: CGFloat
    var lastAttackerId: Int?

    init(id: Int, kind: VehicleKind, team: Team, position: CGPoint, facing: CGFloat, pilotId: Int) {
        self.id = id
        self.kind = kind
        self.team = team
        self.position = position
        self.facing = facing
        aim = facing
        self.pilotId = pilotId
        hp = kind == .tank ? VehicleConfig.tankHP : VehicleConfig.helicopterHP
        timeLeft = kind == .helicopter ? VehicleConfig.helicopterTime : .greatestFiniteMagnitude
    }

    var isAlive: Bool { hp > 0 && pilotId != nil }
    var radius: CGFloat { kind == .tank ? VehicleConfig.tankRadius : VehicleConfig.helicopterRadius }
    var maxHP: CGFloat { kind == .tank ? VehicleConfig.tankHP : VehicleConfig.helicopterHP }
    var flies: Bool { kind == .helicopter }
}
