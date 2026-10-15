import AppKit
import SpriteKit

/// Switches between the main menu and matches. Owns the shared input and sound engine.
@MainActor
final class SceneRouter {
    let view: GameView
    let input: InputManager
    let sound = SoundEngine()
    private(set) var settings = GameSettings()

    init(view: GameView, input: InputManager) {
        self.view = view
        self.input = input
    }

    func showMainMenu() {
        input.reset()
        let scene = MainMenuScene(size: view.bounds.size, router: self, settings: settings)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    func startGame(settings: GameSettings) {
        self.settings = settings
        input.reset()
        let scene = GameScene(size: view.bounds.size, router: self, settings: settings)
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
