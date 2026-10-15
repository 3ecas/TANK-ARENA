import SpriteKit

/// Builds the right sprite stack for each entity kind.
@MainActor
enum EntityViewFactory {
    static func makeView(for entity: Entity, playerTeam: Team, isPlayer: Bool) -> EntityView {
        let team = entity.team
        let view: EntityView
        switch entity.kind {
        case .hero, .rifleman, .squadSoldier, .mercenary:
            view = infantry(UnitTextures.soldier(team: team, hero: entity.kind == .hero), size: entity.kind == .hero ? 36 : 28)
        case .rocketSoldier, .heavyMercenary:
            let side: CGFloat = entity.kind == .heavyMercenary ? 34 : 28
            view = infantry(UnitTextures.soldier(team: team, hero: false, rocket: true), size: side)
        case .tank, .apc, .superTank, .summonTank, .depotGuardian:
            view = vehicle(entity)
        case .helicopter:
            view = helicopter(entity)
        case .sentry:
            view = EntityView(body: sprite(UnitTextures.sentryBase(team: team)))
            view.turret = sprite(UnitTextures.turret(kind: .sentry, team: team))
        case .bunker, .barracks, .hq:
            view = EntityView(body: sprite(StructureTextures.structure(kind: entity.kind, team: team)))
            view.body.zPosition = -1
            if entity.kind != .barracks {
                view.turret = sprite(UnitTextures.turret(kind: entity.kind == .hq ? .superTank : .tank, team: team))
            }
        }
        if let turret = view.turret { view.root.addChild(turret) }
        addHealthBar(to: view, entity: entity, playerTeam: playerTeam, isPlayer: isPlayer)
        if isPlayer { addPlayerRing(to: view) }
        return view
    }

    private static func sprite(_ texture: SKTexture) -> SKSpriteNode {
        let node = TextureFactory.sprite(texture)
        node.color = SKColor(red: 0.4, green: 0.7, blue: 1, alpha: 1)
        return node
    }

    private static func infantry(_ texture: SKTexture, size: CGFloat) -> EntityView {
        let body = sprite(texture)
        body.size = CGSize(width: size, height: size)
        let view = EntityView(body: body)
        view.bodyFollowsAim = true
        return view
    }

    private static func vehicle(_ entity: Entity) -> EntityView {
        let view = EntityView(body: sprite(UnitTextures.hull(kind: entity.kind, team: entity.team)))
        let shadow = sprite(UnitTextures.shadow(width: view.body.size.width + 8, height: view.body.size.height + 8))
        shadow.position = CGPoint(x: 4, y: -4)
        shadow.zPosition = -1
        view.root.addChild(shadow)
        view.turret = sprite(UnitTextures.turret(kind: entity.kind, team: entity.team))
        view.turret?.zPosition = 1
        return view
    }

    private static func helicopter(_ entity: Entity) -> EntityView {
        let altitude = SummonConfig.helicopterAltitude
        let view = EntityView(body: sprite(UnitTextures.helicopter(team: entity.team)))
        view.altitude = altitude
        view.body.position = CGPoint(x: 0, y: altitude)
        let shadow = sprite(UnitTextures.shadow(width: 64, height: 26))
        shadow.zPosition = -1
        view.root.addChild(shadow)
        let rotor = sprite(UnitTextures.rotor())
        rotor.position = CGPoint(x: 0, y: altitude)
        rotor.zPosition = 2
        view.root.addChild(rotor)
        view.rotor = rotor
        return view
    }

    private static func addHealthBar(to view: EntityView, entity: Entity, playerTeam: Team, isPlayer: Bool) {
        let color: SKColor
        if isPlayer {
            color = Palette.player
        } else if entity.team == .neutral {
            color = Palette.team(.neutral)
        } else {
            color = entity.team == playerTeam ? Palette.team(.blue) : Palette.team(.red)
        }
        let width: CGFloat
        if entity.kind.isStructure { width = entity.radius * 1.6 } else if entity is Hero { width = 46 } else { width = Swift.max(26, entity.radius * 2) }
        let bar = HealthBarNode(width: width, height: entity is Hero || entity.kind.isStructure ? 6 : 4, color: color)
        bar.position = CGPoint(x: 0, y: entity.radius + 12 + view.altitude)
        bar.zPosition = 5
        view.root.addChild(bar)
        view.healthBar = bar
        if let hero = entity as? Hero {
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.fontSize = 10
            label.fontColor = SKColor(white: 1, alpha: 0.9)
            label.text = "\(hero.name)  Lv \(hero.level)"
            label.position = CGPoint(x: 0, y: entity.radius + 20)
            label.verticalAlignmentMode = .bottom
            label.zPosition = 5
            view.root.addChild(label)
            view.label = label
        }
    }

    private static func addPlayerRing(to view: EntityView) {
        let ring = TextureFactory.sprite(EffectTextures.ring(radius: 24, lineWidth: 2))
        ring.color = Palette.player
        ring.colorBlendFactor = 1
        ring.alpha = 0.8
        ring.zPosition = -2
        view.root.addChild(ring)
    }
}
