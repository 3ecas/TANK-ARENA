import AppKit
import SpriteKit

/// Switches between the main menu and battles. Owns the shared input and sound engine.
@MainActor
final class SceneRouter {
    let view: GameView
    let input: InputManager
    let sound = SoundEngine()

    init(view: GameView, input: InputManager) {
        self.view = view
        self.input = input
    }

    func showMainMenu() {
        input.reset()
        let scene = MainMenuScene(size: view.bounds.size, router: self)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    func startGame() {
        input.reset()
        let scene = GameScene(size: view.bounds.size, router: self)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
