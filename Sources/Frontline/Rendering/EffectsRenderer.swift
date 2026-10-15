import SpriteKit

/// Turns game events into visual feedback: tracers, muzzle flashes, explosions,
/// EMP pulses, scorch marks, floating numbers and aircraft flyovers.
@MainActor
final class EffectsRenderer {
    private unowned let session: GameSession
    private let pool: EffectPool
    private let decals: EffectPool
    private let text: FloatingTextLayer
    private let flyovers: FlyoverRenderer
    /// Called for big explosions (magnitude, position) so the camera can shake.
    var onBigExplosion: ((CGFloat, CGPoint) -> Void)?

    init(session: GameSession, effectLayer: SKNode, decalLayer: SKNode, textLayer: SKNode,
         airLayer: SKNode, shadowLayer: SKNode) {
        let floatingText = FloatingTextLayer()
        self.session = session
        pool = EffectPool(layer: effectLayer)
        decals = EffectPool(layer: decalLayer, maxActive: 160)
        text = floatingText
        flyovers = FlyoverRenderer(airLayer: airLayer, shadowLayer: shadowLayer)
        textLayer.addChild(floatingText.layer)
        session.bus.subscribe { [unowned self] event in self.handle(event) }
    }

    func update(dt: CGFloat) {
        pool.update(dt: dt)
        decals.update(dt: dt)
        text.update(dt: dt)
        flyovers.update(dt: dt)
    }

    private var playerId: Int { session.player.id }

    private func visible(_ p: CGPoint) -> Bool {
        session.ctx.vision.isVisible(p, to: session.player.team)
    }

    private func handle(_ event: GameEvent) {
        switch event {
        case .shotFired(_, let from, let to, let kind):
            if visible(from) || visible(to) { shot(from: from, to: to, kind: kind) }
        case .projectileImpact(let position, let kind):
            if visible(position) { impact(at: position, kind: kind) }
        case .explosion(let position, let radius, let big):
            explosion(at: position, radius: radius, big: big)
        case .empPulse(let position, let radius):
            empPulse(at: position, radius: radius)
        case .damaged(let targetId, let sourceId, let amount, let position):
            damageNumber(targetId: targetId, sourceId: sourceId, amount: amount, position: position)
        case .healed(let targetId, let amount, let position):
            if let target = session.world.entity(targetId), target.team == session.player.team, visible(position) {
                text.spawn("+\(Int(amount))", at: position, color: Palette.heal, fontSize: 13)
            }
        case .goldGained(let heroId, let amount, let position):
            if heroId == playerId { text.spawn("+\(amount)g", at: position, color: Palette.gold, fontSize: 13) }
        case .levelUp(let heroId, let level):
            if heroId == playerId {
                text.spawn("LEVEL \(level)!", at: session.player.position + CGPoint(x: 0, y: 30),
                           color: Palette.gold, fontSize: 18, life: 1.6, rise: 60)
            }
        case .killed(let victimId, _):
            if let victim = session.world.entity(victimId), victim.kind.isInfantry, visible(victim.position) {
                pool.spawn(EffectTextures.puff, at: victim.position, size: CGSize(width: 34, height: 34),
                           color: SKColor(white: 0.55, alpha: 1), alpha: 0.8, life: 0.7, endScale: 1.6)
            }
        case .structureDestroyed(let structureId, _, _):
            if let structure = session.world.entity(structureId) {
                decals.spawn(StructureTextures.rubble(), at: structure.position,
                             size: CGSize(width: structure.radius * 2.6, height: structure.radius * 2.6),
                             life: 100_000)
            }
        case .aircraftPass(let from, let to, let duration, let kind):
            flyovers.launch(from: from, to: to, duration: duration, kind: kind)
        default:
            break
        }
    }

    private func shot(from: CGPoint, to: CGPoint, kind: ProjectileKind) {
        let delta = to - from
        let angle = delta.angle
        if kind == .bullet, !pool.isSaturated {
            pool.spawn(EffectTextures.tracer, at: from.lerp(to: to, t: 0.5),
                       size: CGSize(width: Swift.max(delta.length, 4), height: 2),
                       alpha: 0.9, life: 0.07, rotation: angle, additive: true)
        }
        let flashSize = kind == .bullet ? CGSize(width: 14, height: 9) : CGSize(width: 24, height: 16)
        pool.spawn(EffectTextures.muzzleFlash, at: from + CGPoint(angle: angle, length: flashSize.width / 2),
                   size: flashSize, life: 0.05, rotation: angle, additive: true)
        if kind != .bullet {
            pool.spawn(EffectTextures.puff, at: from, size: CGSize(width: 18, height: 18),
                       color: SKColor(white: 0.7, alpha: 1), alpha: 0.6, life: 0.5, endScale: 1.8)
        }
    }

    private func impact(at position: CGPoint, kind: ProjectileKind) {
        let size: CGFloat = kind == .grenade ? 40 : 20
        pool.spawn(EffectTextures.puff, at: position, size: CGSize(width: size, height: size),
                   color: SKColor(red: 0.6, green: 0.55, blue: 0.45, alpha: 1), alpha: 0.7, life: 0.45, endScale: 1.5)
    }

    private func explosion(at position: CGPoint, radius: CGFloat, big: Bool) {
        let onScreen = visible(position)
        if big { onBigExplosion?(Swift.min(14, 4 + radius / 18), position) }
        decals.spawn(EffectTextures.glow, at: position, size: CGSize(width: radius * 1.7, height: radius * 1.7),
                     color: SKColor(white: 0.05, alpha: 1), alpha: 0.45, life: 14)
        guard onScreen else { return }
        let flash = CGSize(width: radius * 2.4, height: radius * 2.4)
        pool.spawn(EffectTextures.glow, at: position, size: flash, color: SKColor(red: 1, green: 0.6, blue: 0.2, alpha: 1),
                   life: 0.3, startScale: 0.5, endScale: 1.2, additive: true)
        pool.spawn(EffectTextures.glow, at: position, size: CGSize(width: radius, height: radius),
                   color: SKColor(red: 1, green: 0.95, blue: 0.7, alpha: 1), life: 0.15, endScale: 1.4, additive: true)
        let puffs = big ? 9 : 5
        for i in 0..<puffs {
            let angle = CGFloat(i) / CGFloat(puffs) * 2 * .pi + CGFloat.random(in: -0.3...0.3)
            let speed = radius * CGFloat.random(in: 0.9...1.8)
            pool.spawn(EffectTextures.puff, at: position, size: CGSize(width: radius * 0.8, height: radius * 0.8),
                       color: SKColor(white: CGFloat.random(in: 0.25...0.45), alpha: 1), alpha: 0.85,
                       life: CGFloat.random(in: 0.7...1.2), velocity: CGPoint(angle: angle, length: speed),
                       startScale: 0.6, endScale: 1.6, drag: 2.5, spin: CGFloat.random(in: -2...2))
        }
        for _ in 0..<(big ? 8 : 4) {
            let velocity = CGPoint(angle: CGFloat.random(in: 0..<(2 * .pi)), length: radius * CGFloat.random(in: 2...4))
            pool.spawn(EffectTextures.glow, at: position, size: CGSize(width: 6, height: 6),
                       color: SKColor(red: 1, green: 0.8, blue: 0.3, alpha: 1), life: 0.4, velocity: velocity,
                       drag: 3, additive: true)
        }
    }

    private func empPulse(at position: CGPoint, radius: CGFloat) {
        let ringTexture = EffectTextures.ring(radius: radius, lineWidth: 6)
        pool.spawn(ringTexture, at: position, size: TextureFactory.size(of: ringTexture),
                   color: SKColor(red: 0.4, green: 0.85, blue: 1, alpha: 1), life: 0.6, startScale: 0.2, endScale: 1.05,
                   additive: true)
        pool.spawn(EffectTextures.glow, at: position, size: CGSize(width: radius * 2, height: radius * 2),
                   color: SKColor(red: 0.3, green: 0.7, blue: 1, alpha: 1), alpha: 0.7, life: 0.5, additive: true)
        onBigExplosion?(6, position)
    }

    private func damageNumber(targetId: Int, sourceId: Int?, amount: CGFloat, position: CGPoint) {
        let world = session.world
        let source = world.entity(sourceId)
        let creditId = source.map { $0.ownerId ?? $0.id }
        let value = "\(Int(amount.rounded()))"
        if targetId == playerId {
            text.spawn(value, at: position, color: Palette.damageTaken, fontSize: 13)
        } else if creditId == playerId {
            let color = amount >= 100 ? Palette.gold : SKColor.white
            text.spawn(value, at: position, color: color, fontSize: amount >= 100 ? 17 : 13)
        } else if amount >= 90 && visible(position) {
            text.spawn(value, at: position, color: SKColor(white: 0.8, alpha: 0.9), fontSize: 11)
        }
    }
}
