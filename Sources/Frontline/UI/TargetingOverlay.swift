import SpriteKit

/// World-space aiming feedback: weapon range, locked-target ring, ability reticles and area previews.
@MainActor
final class TargetingOverlay {
    let root = SKNode()
    private let rangeRing = SKSpriteNode()
    private let targetRing: SKSpriteNode
    private let abilityRange = SKSpriteNode()
    private let areaFill: SKSpriteNode
    private let areaRing = SKSpriteNode()
    private let lineFill: SKSpriteNode
    private let cursor: SKSpriteNode
    private var time: CGFloat = 0

    init() {
        targetRing = TextureFactory.sprite(EffectTextures.ring(radius: 30, lineWidth: 3))
        areaFill = SKSpriteNode(texture: EffectTextures.disc, size: CGSize(width: 10, height: 10))
        lineFill = SKSpriteNode(texture: EffectTextures.pixel, size: CGSize(width: 10, height: 10))
        cursor = TextureFactory.sprite(EffectTextures.reticle)
        for node in [rangeRing, abilityRange, areaRing] { node.alpha = 0.55 }
        for node in [rangeRing, targetRing, abilityRange, areaFill, areaRing, lineFill, cursor] {
            node.colorBlendFactor = 1
            node.isHidden = true
            root.addChild(node)
        }
        rangeRing.color = .white
        targetRing.color = Palette.warning
        abilityRange.color = Palette.commandPoints
        areaFill.color = Palette.allyStrike
        areaFill.alpha = 0.25
        areaRing.color = Palette.allyStrike
        lineFill.color = Palette.allyStrike
        lineFill.alpha = 0.3
        cursor.color = .white
        cursor.alpha = 0.8
    }

    func update(dt: CGFloat, player: Hero, target: Entity?, showRange: Bool, aiming: AbilityDef?, mouse: CGPoint) {
        time += dt
        let alive = player.isAlive
        cursor.isHidden = false
        cursor.position = mouse

        rangeRing.isHidden = !(alive && (showRange || target != nil))
        if !rangeRing.isHidden { place(rangeRing, radius: player.stats.range, at: player.position) }

        targetRing.isHidden = target == nil
        if let target = target {
            targetRing.position = target.position
            targetRing.setScale((target.radius + 12) / 30 * (1 + 0.08 * sin(time * 8)))
        }
        updateAbility(aiming: alive ? aiming : nil, player: player, mouse: mouse)
    }

    private func updateAbility(aiming def: AbilityDef?, player: Hero, mouse: CGPoint) {
        guard let def = def else {
            for node in [abilityRange, areaFill, areaRing, lineFill] { node.isHidden = true }
            return
        }
        abilityRange.isHidden = def.range <= 0
        if def.range > 0 { place(abilityRange, radius: def.range, at: player.position) }
        let target = AbilityGeometry.clampedTarget(def, caster: player.position, cursor: mouse)
        switch def.castMode {
        case .line(let length):
            areaFill.isHidden = true
            areaRing.isHidden = true
            lineFill.isHidden = false
            let line = AbilityGeometry.strafeLine(caster: player.position, target: target, length: length,
                                                  fallbackAngle: player.bodyAngle)
            lineFill.position = line.from.lerp(to: line.to, t: 0.5)
            lineFill.size = CGSize(width: length, height: def.radius * 2)
            lineFill.zRotation = (line.to - line.from).angle
        default:
            lineFill.isHidden = true
            areaFill.isHidden = false
            areaRing.isHidden = false
            let radius = Swift.max(def.radius, 30)
            areaFill.position = target
            areaFill.size = CGSize(width: radius * 2, height: radius * 2)
            place(areaRing, radius: radius, at: target)
        }
    }

    private func place(_ node: SKSpriteNode, radius: CGFloat, at position: CGPoint) {
        let texture = EffectTextures.ring(radius: radius, lineWidth: 2)
        if node.texture !== texture {
            node.texture = texture
            node.size = TextureFactory.size(of: texture)
        }
        node.position = position
    }
}
