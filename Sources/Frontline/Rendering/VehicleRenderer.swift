import SpriteKit

/// Tanks (hull, tracks, turret) and helicopters (body, tail, spinning rotor) in team colours, with a health
/// bar. Enemy vehicles are only drawn while their pilot can be seen.
@MainActor
final class VehicleRenderer {
    let root = SKNode()
    private var views: [Int: VehicleView] = [:]

    func update(dt: CGFloat, world: BattleWorld, playerTeam: Team, isShown: (Soldier) -> Bool) {
        var live = Set<Int>()
        for vehicle in world.vehicles where vehicle.isAlive {
            live.insert(vehicle.id)
            let view: VehicleView
            if let existing = views[vehicle.id] {
                view = existing
            } else {
                view = VehicleView(vehicle: vehicle, friendly: vehicle.team == playerTeam)
                root.addChild(view.node)
                views[vehicle.id] = view
            }
            let visible = vehicle.team == playerTeam || world.soldier(vehicle.pilotId).map(isShown) == true
            view.node.isHidden = !visible
            if visible { view.sync(vehicle, dt: dt) }
        }
        for (id, view) in views where !live.contains(id) {
            view.node.removeFromParent()
            views[id] = nil
        }
    }
}

@MainActor
private final class VehicleView {
    let node = SKNode()
    private let body = SKNode()
    private let turret = SKNode()
    private var rotor: SKShapeNode?
    private let healthBar: HealthBarNode

    init(vehicle: Vehicle, friendly: Bool) {
        let color = Palette.team(vehicle.team)
        let dark = SKColor(cgColor: Palette.teamDarkCG(vehicle.team)) ?? .darkGray
        healthBar = HealthBarNode(width: 54, height: 4, color: friendly ? Palette.team(.blue) : Palette.team(.red))
        healthBar.position = CGPoint(x: 0, y: vehicle.radius + 14)
        switch vehicle.kind {
        case .tank:
            for side in [CGFloat(1), -1] {
                let track = SKShapeNode(rectOf: CGSize(width: 76, height: 16), cornerRadius: 4)
                track.fillColor = SKColor(white: 0.12, alpha: 1)
                track.strokeColor = .black
                track.position = CGPoint(x: 0, y: 24 * side)
                body.addChild(track)
            }
            let hull = SKShapeNode(rectOf: CGSize(width: 70, height: 40), cornerRadius: 6)
            hull.fillColor = dark
            hull.strokeColor = color
            hull.lineWidth = 2
            body.addChild(hull)
            let dome = SKShapeNode(circleOfRadius: 15)
            dome.fillColor = color
            dome.strokeColor = .black
            let barrel = SKShapeNode(rectOf: CGSize(width: 44, height: 7), cornerRadius: 2)
            barrel.fillColor = SKColor(white: 0.2, alpha: 1)
            barrel.strokeColor = .black
            barrel.position = CGPoint(x: 30, y: 0)
            turret.addChild(barrel)
            turret.addChild(dome)
        case .helicopter:
            let tail = SKShapeNode(rectOf: CGSize(width: 46, height: 7), cornerRadius: 3)
            tail.fillColor = dark
            tail.strokeColor = .black
            tail.position = CGPoint(x: -34, y: 0)
            let cabin = SKShapeNode(ellipseOf: CGSize(width: 56, height: 32))
            cabin.fillColor = color
            cabin.strokeColor = .black
            cabin.lineWidth = 2
            let glass = SKShapeNode(ellipseOf: CGSize(width: 16, height: 18))
            glass.fillColor = SKColor(red: 0.6, green: 0.8, blue: 0.95, alpha: 0.9)
            glass.strokeColor = .clear
            glass.position = CGPoint(x: 16, y: 0)
            body.addChild(tail)
            body.addChild(cabin)
            body.addChild(glass)
            let blades = SKShapeNode(rectOf: CGSize(width: 96, height: 5), cornerRadius: 2)
            blades.fillColor = SKColor(white: 0.1, alpha: 0.75)
            blades.strokeColor = .clear
            let cross = SKShapeNode(rectOf: CGSize(width: 5, height: 96), cornerRadius: 2)
            cross.fillColor = SKColor(white: 0.1, alpha: 0.75)
            cross.strokeColor = .clear
            blades.addChild(cross)
            blades.zPosition = 3
            node.addChild(blades)
            rotor = blades
            node.zPosition = 30
        }
        node.addChild(body)
        node.addChild(turret)
        node.addChild(healthBar)
    }

    func sync(_ vehicle: Vehicle, dt: CGFloat) {
        node.position = vehicle.position
        body.zRotation = vehicle.facing
        turret.zRotation = vehicle.aim
        rotor?.zRotation += 25 * dt
        healthBar.setFraction(vehicle.hp / vehicle.maxHP, invulnerable: false)
    }
}

/// Medic health boxes (white, red cross) and engineer ammo boxes (olive, bullets) for your team, fading out
/// before they expire.
@MainActor
final class SupplyRenderer {
    let root = SKNode()
    private var nodes: [Int: SKNode] = [:]

    func update(world: BattleWorld, playerTeam: Team) {
        var live = Set<Int>()
        for box in world.boxes where box.timeLeft > 0 && box.team == playerTeam {
            live.insert(box.id)
            let node = nodes[box.id] ?? makeNode(box)
            node.alpha = box.timeLeft < 4 ? 0.4 + 0.6 * abs(sin(box.timeLeft * 6)) : 1
        }
        for (id, node) in nodes where !live.contains(id) {
            node.removeFromParent()
            nodes[id] = nil
        }
    }

    private func makeNode(_ box: SupplyBox) -> SKNode {
        let node = SKNode()
        let health = box.kind == .health
        let crate = SKShapeNode(rectOf: CGSize(width: 24, height: 18), cornerRadius: 3)
        crate.fillColor = health ? SKColor(white: 0.92, alpha: 1) : SKColor(red: 0.35, green: 0.42, blue: 0.22, alpha: 1)
        crate.strokeColor = .black
        node.addChild(crate)
        let mark = SKShapeNode(rectOf: health ? CGSize(width: 12, height: 4) : CGSize(width: 4, height: 10))
        mark.fillColor = health ? .red : SKColor(red: 0.95, green: 0.8, blue: 0.3, alpha: 1)
        mark.strokeColor = .clear
        node.addChild(mark)
        if health {
            let bar = SKShapeNode(rectOf: CGSize(width: 4, height: 12))
            bar.fillColor = .red
            bar.strokeColor = .clear
            node.addChild(bar)
        }
        let ring = SKShapeNode(circleOfRadius: ClassConfig.boxRadius)
        ring.strokeColor = (health ? SKColor.red : SKColor.yellow).withAlphaComponent(0.25)
        ring.lineWidth = 1.5
        node.addChild(ring)
        node.position = box.position
        root.addChild(node)
        nodes[box.id] = node
        return node
    }
}
