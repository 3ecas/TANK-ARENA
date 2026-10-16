import SpriteKit

/// Sites (ring + letter) and every bomb: the carried / dropped / planted bomb of bomb mode, or the
/// station on each rush site. Armed bombs blink red, faster as the fuse runs out; destroyed stations show
/// as scorched wreckage. A carried bomb is only drawn while its carrier is visible.
@MainActor
final class SiteRenderer {
    let root = SKNode()
    private var rings: [SKShapeNode] = []
    private var letters: [SKLabelNode] = []
    private var views: [BombView] = []
    private var blink: CGFloat = 0
    private let playerTeam: Team

    init(world: BattleWorld, playerTeam: Team) {
        self.playerTeam = playerTeam
        for site in world.sites {
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
            letter.position = site.center + CGPoint(x: 0, y: 70)
            root.addChild(ring)
            root.addChild(letter)
            rings.append(ring)
            letters.append(letter)
        }
        for _ in world.bombs {
            let view = BombView(station: world.mode == .rush)
            root.addChild(view.node)
            views.append(view)
        }
    }

    func update(dt: CGFloat, world: BattleWorld, isShown: (Soldier) -> Bool, canSee: (CGPoint) -> Bool) {
        blink += dt
        for (index, site) in world.sites.enumerated() {
            let armed = world.bombs.contains { $0.isPlanted && $0.site === site }
            let destroyed = world.mode == .rush && world.station(at: site)?.isExploded == true
            rings[index].lineWidth = armed ? 8 : 5
            rings[index].alpha = destroyed ? 0.25 : (armed ? 0.6 + 0.4 * abs(sin(blink * 5)) : 1)
            letters[index].alpha = destroyed ? 0.3 : 1
        }
        for (view, bomb) in zip(views, world.bombs) {
            view.update(bomb: bomb, world: world, blink: blink, playerTeam: playerTeam, isShown: isShown, canSee: canSee)
        }
    }
}

/// One bomb or rush station on screen.
@MainActor
private final class BombView {
    let node = SKNode()
    private let body: SKShapeNode
    private let light = SKShapeNode(circleOfRadius: 5)
    private let isStation: Bool

    init(station: Bool) {
        isStation = station
        body = SKShapeNode(rectOf: station ? CGSize(width: 40, height: 28) : CGSize(width: 22, height: 14), cornerRadius: 3)
        body.fillColor = SKColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1)
        body.strokeColor = SKColor(red: 0.95, green: 0.6, blue: 0.2, alpha: 1)
        body.lineWidth = 2
        light.fillColor = .red
        light.strokeColor = .clear
        light.position = CGPoint(x: station ? 10 : 5, y: 0)
        node.addChild(body)
        node.addChild(light)
        node.zPosition = 2
    }

    func update(bomb: Bomb, world: BattleWorld, blink: CGFloat, playerTeam: Team,
                isShown: (Soldier) -> Bool, canSee: (CGPoint) -> Bool) {
        body.fillColor = SKColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1)
        switch bomb.state {
        case .carried(let id):
            guard let carrier = world.soldier(id), isShown(carrier) else {
                node.isHidden = true
                return
            }
            show(at: carrier.position + CGPoint(x: -14, y: -16), lightOn: false)
        case .dropped:
            // Attackers always know where their bomb lies; defenders only when they can see it.
            node.isHidden = !(world.attackers == playerTeam || canSee(bomb.position))
            node.position = bomb.position
            light.isHidden = true
        case .idle:
            show(at: bomb.position, lightOn: false)
        case .planted:
            let rate = 2 + 10 * (1 - bomb.fuseLeft / BombConfig.fuseTime)
            show(at: bomb.position, lightOn: sin(blink * rate * .pi) >= 0)
        case .defused:
            show(at: bomb.position, lightOn: false)
        case .exploded:
            if isStation {
                body.fillColor = SKColor(white: 0.08, alpha: 1)
                show(at: bomb.position, lightOn: false)
            } else {
                node.isHidden = true
            }
        }
    }

    private func show(at position: CGPoint, lightOn: Bool) {
        node.isHidden = false
        node.position = position
        light.isHidden = !lightOn
    }
}
