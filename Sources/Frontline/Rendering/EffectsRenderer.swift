import SpriteKit

/// Turns battle events into visuals: tracers, muzzle flashes, wall sparks, blood,
/// grenade blasts (frag / flash / stun) and knife swipes.
@MainActor
final class EffectsRenderer {
    private unowned let session: GameSession
    private let pool: EffectPool
    private let decals: EffectPool
    /// Called for blasts near the camera (magnitude, position) so the camera can shake.
    var onBlast: ((CGFloat, CGPoint) -> Void)?

    init(session: GameSession, effectLayer: SKNode, decalLayer: SKNode) {
        self.session = session
        pool = EffectPool(layer: effectLayer, maxActive: 900)
        decals = EffectPool(layer: decalLayer, maxActive: 220)
        session.bus.subscribe { [unowned self] event in self.handle(event) }
    }

    func update(dt: CGFloat) {
        pool.update(dt: dt)
        decals.update(dt: dt)
    }

    private func handle(_ event: GameEvent) {
        switch event {
        case .shotFired(_, let from, let to, let weapon, let hitWall):
            shot(from: from, to: to, weapon: weapon, hitWall: hitWall)
        case .soldierHit(_, _, _, let position):
            pool.spawn(EffectTextures.glow, at: position, size: CGSize(width: 18, height: 18),
                       color: SKColor(red: 0.75, green: 0.05, blue: 0.05, alpha: 1), alpha: 0.9, life: 0.3, endScale: 1.6)
        case .soldierKilled(let victimId, _, _):
            if let victim = session.world.soldier(victimId) {
                decals.spawn(SoldierTextures.bloodSplat(), at: victim.position, size: CGSize(width: 38, height: 38),
                             life: 40, rotation: CGFloat.random(in: 0..<(2 * .pi)))
            }
        case .grenadeExploded(let type, let position, let radius):
            blast(type, at: position, radius: radius)
        case .knifeSwing(_, let position, let angle, _):
            pool.spawn(EffectTextures.tracer, at: position + CGPoint(angle: angle, length: 26),
                       size: CGSize(width: 22, height: 3), alpha: 0.9, life: 0.12, rotation: angle + .pi / 2)
        default:
            break
        }
    }

    private func shot(from: CGPoint, to: CGPoint, weapon: WeaponID, hitWall: Bool) {
        let delta = to - from
        let angle = delta.angle
        pool.spawn(EffectTextures.tracer, at: from.lerp(to: to, t: 0.5),
                   size: CGSize(width: Swift.max(delta.length, 4), height: weapon == .rpg ? 5 : 2),
                   alpha: 0.85, life: 0.06, rotation: angle, additive: true)
        pool.spawn(EffectTextures.muzzleFlash, at: from + CGPoint(angle: angle, length: 6),
                   size: CGSize(width: 14, height: 9), life: 0.05, rotation: angle, additive: true)
        if hitWall {
            pool.spawn(EffectTextures.puff, at: to, size: CGSize(width: 12, height: 12),
                       color: SKColor(white: 0.75, alpha: 1), alpha: 0.8, life: 0.35, endScale: 1.6)
        }
    }

    private func blast(_ type: GrenadeType, at position: CGPoint, radius: CGFloat) {
        switch type {
        case .frag:
            onBlast?(10, position)
            decals.spawn(EffectTextures.glow, at: position, size: CGSize(width: radius, height: radius),
                         color: SKColor(white: 0.05, alpha: 1), alpha: 0.5, life: 20)
            pool.spawn(EffectTextures.glow, at: position, size: CGSize(width: radius * 1.6, height: radius * 1.6),
                       color: SKColor(red: 1, green: 0.6, blue: 0.2, alpha: 1), life: 0.3, startScale: 0.4,
                       endScale: 1.1, additive: true)
            for i in 0..<10 {
                let angle = CGFloat(i) / 10 * 2 * .pi
                pool.spawn(EffectTextures.puff, at: position, size: CGSize(width: 50, height: 50),
                           color: SKColor(white: CGFloat.random(in: 0.25...0.45), alpha: 1), alpha: 0.85,
                           life: CGFloat.random(in: 0.7...1.1), velocity: CGPoint(angle: angle, length: radius * 1.2),
                           startScale: 0.6, endScale: 1.6, drag: 2.5)
            }
        case .flash:
            onBlast?(3, position)
            pool.spawn(EffectTextures.glow, at: position, size: CGSize(width: radius * 1.2, height: radius * 1.2),
                       color: .white, life: 0.4, startScale: 0.2, endScale: 1.2, additive: true)
        case .stun:
            let ring = EffectTextures.ring(radius: radius, lineWidth: 6)
            pool.spawn(ring, at: position, size: TextureFactory.size(of: ring),
                       color: SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 1), life: 0.5, startScale: 0.2,
                       endScale: 1.05, additive: true)
            pool.spawn(EffectTextures.glow, at: position, size: CGSize(width: radius * 1.5, height: radius * 1.5),
                       color: SKColor(red: 0.3, green: 0.6, blue: 1, alpha: 1), alpha: 0.6, life: 0.4, additive: true)
        }
    }
}
