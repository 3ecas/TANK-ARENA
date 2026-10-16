import AppKit
import SpriteKit

/// Switches between the main menu and battles. Owns the shared input and sound engine.
@MainActor
final class SceneRouter {
    let view: GameView
    let input: InputManager
    let sound = SoundEngine()
    /// Mode of the last battle (Play Again / Enter reuse it).
    private(set) var lastMode: GameMode = .bomb
    /// Class picked in the main menu.
    var playerClass: SoldierClass = .assault

    init(view: GameView, input: InputManager) {
        self.view = view
        self.input = input
    }

    func showMainMenu() {
        input.reset()
        let scene = MainMenuScene(size: view.bounds.size, router: self)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    /// Starts a round on a freshly generated office; the player's side (attack / defend) is random.
    func startGame(mode: GameMode? = nil) {
        input.reset()
        let chosen = mode ?? lastMode
        lastMode = chosen
        let scene = GameScene(size: view.bounds.size, router: self, mode: chosen, attacking: Bool.random(),
                              playerClass: playerClass)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
