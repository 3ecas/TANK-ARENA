import CoreGraphics

/// Everything that happens in a battle that effects, UI or audio may care about.
enum GameEvent {
    case shotFired(shooterId: Int, from: CGPoint, to: CGPoint, weapon: WeaponID, hitWall: Bool)
    case soldierHit(victimId: Int, attackerId: Int?, damage: CGFloat, position: CGPoint)
    case soldierKilled(victimId: Int, killerId: Int?, weaponName: String)
    case soldierRespawned(soldierId: Int)
    case reloadStarted(soldierId: Int)
    case grenadeThrown(soldierId: Int, type: GrenadeType)
    case grenadeExploded(type: GrenadeType, position: CGPoint, radius: CGFloat)
    case knifeSwing(soldierId: Int, position: CGPoint, angle: CGFloat, hit: Bool)
    case bombPickedUp(soldierId: Int)
    case bombDropped(position: CGPoint)
    case bombPlanted(site: String, planterId: Int)
    case bombDefused(defuserId: Int)
    case bombExploded(position: CGPoint)
    case announcement(text: String)
    /// nil winner = draw.
    case matchOver(winner: Team?)
}
