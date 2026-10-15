import CoreGraphics

/// A thrown grenade: rolls toward its target point, bounces off walls, explodes when the fuse ends.
@MainActor
final class Grenade {
    let id: Int
    let type: GrenadeType
    let team: Team
    let ownerId: Int
    var position: CGPoint
    var velocity: CGPoint
    /// Distance still to travel before coming to rest.
    var remainingDistance: CGFloat
    var fuse: CGFloat = GrenadeConfig.fuse
    var isDone = false

    init(id: Int, type: GrenadeType, team: Team, ownerId: Int, from: CGPoint, to: CGPoint) {
        self.id = id
        self.type = type
        self.team = team
        self.ownerId = ownerId
        self.position = from
        let delta = to - from
        self.remainingDistance = delta.length
        self.velocity = delta.normalized * GrenadeConfig.throwSpeed
    }
}
