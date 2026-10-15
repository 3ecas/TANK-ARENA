import SpriteKit

/// Live control-zone visuals: an ownership ring tinted by owner, a capture-progress arc and the zone letter.
@MainActor
final class ZoneRenderer {
    let root = SKNode()
    private let zones: [ControlZone]
    private var rings: [SKShapeNode] = []
    private var arcs: [SKShapeNode] = []
    private var letters: [SKLabelNode] = []
    private var pulse: CGFloat = 0

    init(zones: [ControlZone]) {
        self.zones = zones
        for zone in zones {
            let ring = SKShapeNode(circleOfRadius: zone.radius)
            ring.lineWidth = 6
            ring.position = zone.center
            let arc = SKShapeNode()
            arc.lineWidth = 10
            arc.lineCap = .round
            arc.position = zone.center
            let letter = SKLabelNode(fontNamed: UIStyle.boldFont)
            letter.text = zone.name
            letter.fontSize = 54
            letter.verticalAlignmentMode = .center
            letter.position = zone.center
            for node in [ring, arc, letter] as [SKNode] { root.addChild(node) }
            rings.append(ring)
            arcs.append(arc)
            letters.append(letter)
        }
    }

    func update(dt: CGFloat) {
        pulse += dt
        for (index, zone) in zones.enumerated() {
            let ownerColor = zone.owner.map { Palette.team($0) } ?? SKColor(white: 0.85, alpha: 1)
            let blink = zone.isContested ? 0.5 + 0.5 * abs(sin(pulse * 6)) : 1
            rings[index].strokeColor = ownerColor.withAlphaComponent(0.75 * blink)
            rings[index].fillColor = ownerColor.withAlphaComponent(zone.owner == nil ? 0.05 : 0.12)
            letters[index].fontColor = ownerColor.withAlphaComponent(0.55)
            updateArc(arcs[index], zone: zone)
        }
    }

    /// Arc showing how far the zone has been pulled toward blue (+) or red (-).
    private func updateArc(_ arc: SKShapeNode, zone: ControlZone) {
        let amount = abs(zone.progress)
        guard amount > 0.01, amount < 0.999 || zone.owner == nil else {
            arc.path = nil
            return
        }
        let team: Team = zone.progress > 0 ? .blue : .red
        let path = CGMutablePath()
        let start = CGFloat.pi / 2
        path.addArc(center: .zero, radius: zone.radius + 10, startAngle: start,
                    endAngle: start - amount * 2 * .pi, clockwise: true)
        arc.path = path
        arc.strokeColor = Palette.team(team).withAlphaComponent(0.9)
    }
}
