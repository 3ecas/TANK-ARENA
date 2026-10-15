import CoreGraphics

/// Kinds of aircraft used for call-in visuals.
enum AircraftPassKind {
    case jet, bomber
}

/// Everything that happens in the game that other systems, UI, effects or audio may care about.
enum GameEvent {
    case damaged(targetId: Int, sourceId: Int?, amount: CGFloat, position: CGPoint)
    case healed(targetId: Int, amount: CGFloat, position: CGPoint)
    /// Published while the victim is still in the world.
    case killed(victimId: Int, killerId: Int?)
    case heroAttackedHero(attackerId: Int, victimId: Int)
    case shotFired(sourceId: Int, from: CGPoint, to: CGPoint, kind: ProjectileKind)
    case projectileImpact(position: CGPoint, kind: ProjectileKind)
    case explosion(position: CGPoint, radius: CGFloat, big: Bool)
    case empPulse(position: CGPoint, radius: CGFloat)
    case abilityCast(heroId: Int, ability: AbilityID, target: CGPoint)
    case strikeIncoming(team: Team, position: CGPoint)
    case aircraftPass(from: CGPoint, to: CGPoint, duration: CGFloat, kind: AircraftPassKind)
    case goldGained(heroId: Int, amount: Int, position: CGPoint)
    case levelUp(heroId: Int, level: Int)
    case heroRespawned(heroId: Int)
    case recallStarted(heroId: Int)
    case recallCancelled(heroId: Int)
    case recallCompleted(heroId: Int)
    case structureDestroyed(structureId: Int, team: Team, title: String)
    case objectiveCaptured(title: String, team: Team)
    case announcement(text: String, team: Team?)
    case purchase(heroId: Int)
    case gameOver(winner: Team)
}
