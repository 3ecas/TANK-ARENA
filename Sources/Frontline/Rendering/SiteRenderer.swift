import SpriteKit

/// Bomb sites (ring + letter) and the bomb itself: a small charge on the ground when dropped or planted,
/// with a red light that blinks faster as the fuse runs out. The carried bomb is drawn on the carrier
/// only while the carrier is visible.
@MainActor
final class SiteRenderer {
    let root = SKNode()
    private var rings: [SKShapeNode] = []
    private let bombNode = SKNode()
    private let light = SKShapeNode(circleOfRadius: 4)
    private var blink: CGFloat = 0

    private let playerTeam: Team

    init(sites: [BombSite], playerTeam: Team) {
        self.playerTeam = playerTeam
        for site in sites {
            let ring = SKShapeNode(circleOfRadius: site.radius)
            ring.lineWidth = 5
            ring.strokeColor = SKColor(red: 0.95, green: 0.35, blue: 0.25, alpha: 0.7)
            ring.fillColor = SKColor(red: 0.95, green: 0.35, blue: 0.25, alpha: 0.06)
            ring.position = site.center
            let letter = SKLabelNode(fontNamed: UIStyle.boldFont)
            letter.text = site.name
            letter.fontSize = 64
            letter.fontColor = SKColor(red: 0.95, green: 0.35, blue: 0.25, alpha: 0.35)
            letter.verticalAlignmentMode = .center
            letter.position = site.center
            root.addChild(ring)
            root.addChild(letter)
            rings.append(ring)
        }
        let body = SKShapeNode(rectOf: CGSize(width: 22, height: 14), cornerRadius: 3)
        body.fillColor = SKColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1)
        body.strokeColor = SKColor(red: 0.95, green: 0.6, blue: 0.2, alpha: 1)
        body.lineWidth = 2
        light.fillColor = .red
        light.strokeColor = .clear
        light.position = CGPoint(x: 5, y: 0)
        bombNode.addChild(body)
        bombNode.addChild(light)
        bombNode.zPosition = 2
        root.addChild(bombNode)
    }

    func update(dt: CGFloat, world: BattleWorld, isShown: (Soldier) -> Bool, canSee: (CGPoint) -> Bool) {
        let bomb = world.bomb
        blink += dt
        for (ring, site) in zip(rings, world.sites) {
            let planted = bomb.isPlanted && bomb.site === site
            ring.lineWidth = planted ? 8 : 5
            ring.alpha = planted ? 0.6 + 0.4 * abs(sin(blink * 5)) : 1
        }
        switch bomb.state {
        case .carried(let id):
            guard let carrier = world.soldier(id), isShown(carrier) else {
                bombNode.isHidden = true
                return
            }
            bombNode.isHidden = false
            bombNode.position = carrier.position + CGPoint(x: -14, y: -16)
            light.isHidden = true
        case .dropped:
            // Attackers always know where their bomb lies; defenders only when they can see it.
            bombNode.isHidden = !(world.attackers == playerTeam || canSee(bomb.position))
            bombNode.position = bomb.position
            light.isHidden = true
        case .planted:
            bombNode.isHidden = false
            bombNode.position = bomb.position
            // Blinks faster as the fuse runs out.
            let rate = 2 + 10 * (1 - bomb.fuseLeft / BombConfig.fuseTime)
            light.isHidden = sin(blink * rate * .pi) < 0
        case .defused:
            bombNode.isHidden = false
            light.isHidden = true
        case .exploded:
            bombNode.isHidden = true
        }
    }
}
