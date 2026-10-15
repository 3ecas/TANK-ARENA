import CoreGraphics

/// Maps battle events to sounds, attenuated by distance from the camera.
@MainActor
final class AudioDirector {
    private let sound: SoundEngine
    private unowned let session: GameSession
    /// Returns the current listener (camera) position.
    var listener: () -> CGPoint = { .zero }
    private let hearingRange: CGFloat = 1400

    init(sound: SoundEngine, session: GameSession) {
        self.sound = sound
        self.session = session
        session.bus.subscribe { [unowned self] event in self.handle(event) }
    }

    private func volume(at position: CGPoint) -> Float {
        Float(Swift.max(0, 1 - position.distance(to: listener()) / hearingRange))
    }

    private func handle(_ event: GameEvent) {
        let playerId = session.player.id
        switch event {
        case .shotFired(let shooterId, let from, _, let weapon, _):
            let v = volume(at: from) * (shooterId == playerId ? 1 : 0.5)
            sound.play(shotSound(weapon), volume: v)
        case .soldierHit(let victimId, let attackerId, _, let position):
            if victimId == playerId || attackerId == playerId { sound.play(.hit, volume: 0.6 * volume(at: position)) }
        case .soldierKilled(let victimId, _, _):
            if let victim = session.world.soldier(victimId) { sound.play(.death, volume: 0.5 * volume(at: victim.position)) }
        case .reloadStarted(let soldierId):
            if soldierId == playerId { sound.play(.reload, volume: 0.6) }
        case .grenadeExploded(let type, let position, _):
            let v = volume(at: position)
            switch type {
            case .frag: sound.play(.explosion, volume: v)
            case .flash: sound.play(.flash, volume: v)
            case .stun: sound.play(.stun, volume: v)
            }
        case .knifeSwing(_, let position, _, _):
            sound.play(.knife, volume: volume(at: position))
        case .matchOver:
            sound.play(.click)
        default:
            break
        }
    }

    private func shotSound(_ weapon: WeaponID) -> SoundID {
        switch weapon {
        case .assaultRifle: return .rifle
        case .smg: return .smg
        case .shotgun: return .shotgun
        case .pistol: return .pistol
        }
    }
}
