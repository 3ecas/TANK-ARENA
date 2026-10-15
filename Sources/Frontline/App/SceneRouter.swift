import AppKit
import SpriteKit

/// Switches between the main menu and battles. Owns the shared input and sound engine.
@MainActor
final class SceneRouter {
    let view: GameView
    let input: InputManager
    let sound = SoundEngine()
    /// Map of the last battle (Play Again / Enter reuse it).
    private(set) var lastMap: MapKind = .city
    private(set) var lastAttacking = true

    init(view: GameView, input: InputManager) {
        self.view = view
        self.input = input
    }

    func showMainMenu() {
        input.reset()
        let scene = MainMenuScene(size: view.bounds.size, router: self)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    func startGame(map: MapKind? = nil, attacking: Bool? = nil) {
        input.reset()
        let kind = map ?? lastMap
        let attack = attacking ?? lastAttacking
        lastMap = kind
        lastAttacking = attack
        let scene = GameScene(size: view.bounds.size, router: self, map: kind, attacking: attack)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
