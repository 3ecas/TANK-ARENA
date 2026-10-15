import CoreGraphics

/// Maps game events to sounds, attenuated by distance from the camera.
@MainActor
final class AudioDirector {
    private let sound: SoundEngine
    private unowned let session: GameSession
    /// Returns the current listener (camera) position.
    var listener: () -> CGPoint = { .zero }
    private let hearingRange: CGFloat = 1300

    init(sound: SoundEngine, session: GameSession) {
        self.sound = sound
        self.session = session
        session.bus.subscribe { [unowned self] event in self.handle(event) }
    }

    private func volume(at position: CGPoint) -> Float {
        let distance = position.distance(to: listener())
        return Float(Swift.max(0, 1 - distance / hearingRange))
    }

    private func handle(_ event: GameEvent) {
        let playerId = session.player.id
        switch event {
        case .shotFired(let sourceId, let from, _, let kind):
            let v = volume(at: from) * (sourceId == playerId ? 1 : 0.45)
            sound.play(shotSound(sourceId: sourceId, kind: kind), volume: v)
        case .explosion(let position, _, let big):
            sound.play(big ? .explosionBig : .explosionSmall, volume: volume(at: position))
        case .empPulse(let position, _):
            sound.play(.emp, volume: volume(at: position))
        case .strikeIncoming(let team, let position):
            if team != session.player.team && position.distance(to: session.player.position) < 1400 {
                sound.play(.alert, volume: 0.8)
            }
        case .abilityCast(let heroId, _, _):
            if heroId == playerId { sound.play(.click, volume: 0.7) }
        case .levelUp(let heroId, _):
            if heroId == playerId { sound.play(.levelUp) }
        case .purchase(let heroId):
            if heroId == playerId { sound.play(.purchase) }
        case .healed(let targetId, _, _):
            if targetId == playerId { sound.play(.heal, volume: 0.6) }
        case .objectiveCaptured:
            sound.play(.capture, volume: 0.8)
        case .gameOver:
            sound.play(.levelUp)
        default:
            break
        }
    }

    private func shotSound(sourceId: Int, kind: ProjectileKind) -> SoundID {
        switch kind {
        case .rocket: return .rocket
        case .shell, .cannon, .grenade: return .cannon
        case .bullet:
            guard let hero = session.world.hero(sourceId) else { return .rifle }
            switch hero.weaponId {
            case .assaultRifle: return .rifle
            case .shotgun: return .shotgun
            case .sniperRifle: return .sniper
            case .lmg: return .lmg
            }
        }
    }
}
