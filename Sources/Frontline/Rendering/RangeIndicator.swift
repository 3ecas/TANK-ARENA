import SpriteKit

/// Dashed aim line from the player to the maximum range of the weapon in hand (stopped by walls),
/// with a short arc marking the max range.
@MainActor
final class RangeIndicator {
    let root = SKNode()
    private let line = SKShapeNode()
    private let arc = SKShapeNode()

    init() {
        line.strokeColor = SKColor(white: 1, alpha: 0.28)
        line.lineWidth = 1.5
        arc.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.4, alpha: 0.75)
        arc.lineWidth = 2.5
        arc.lineCap = .round
        root.addChild(line)
        root.addChild(arc)
    }

    func update(player: Soldier, map: ArenaMap) {
        guard player.isAlive else {
            root.isHidden = true
            return
        }
        root.isHidden = false
        let range = player.activeWeapon.def.range
        let direction = CGPoint(angle: player.facing)
        let start = player.position + direction * (player.radius + 8)
        let end = player.position + direction * range
        let blockedAt = map.raycast(from: start, to: end)
        let stop = blockedAt.map { start + (end - start) * $0 } ?? end

        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: stop)
        line.path = path.copy(dashingWithPhase: 0, lengths: [10, 8])

        // The range marker is only drawn when the line reaches it (not cut short by a wall).
        if blockedAt == nil {
            let marker = CGMutablePath()
            let span = GameConfig.rangeMarkerSpan
            marker.addArc(center: player.position, radius: range, startAngle: player.facing - span / 2,
                          endAngle: player.facing + span / 2, clockwise: false)
            arc.path = marker
        } else {
            arc.path = nil
        }
    }
}
