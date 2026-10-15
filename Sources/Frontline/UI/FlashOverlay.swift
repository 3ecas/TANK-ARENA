import SpriteKit

/// Full-screen white-out while the player is blinded by a flashbang.
@MainActor
final class FlashOverlay {
    let node = SKSpriteNode(color: .white, size: CGSize(width: 6000, height: 6000))

    init() {
        node.alpha = 0
        node.isHidden = true
    }

    func update(soldier: Soldier) {
        let strength = soldier.isBlind ? (soldier.blindTime / Swift.max(soldier.blindDuration, 0.01)) : 0
        node.isHidden = strength <= 0
        node.alpha = Swift.min(1, strength * 1.4)
    }
}
