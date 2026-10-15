import SpriteKit

/// Scene-level keys (Esc, Tab, Space, F1) and routing of clicks between HUD and gameplay.
extension GameScene {
    func processInput() {
        let input = router.input
        var leftAvailable = true
        if input.leftPressed && hud.handleClick(scenePoint: mouseScene, scene: self) {
            leftAvailable = false
            input.consumeLeftPress()
        }
        if input.wasPressed(KeyCode.escape) && !gameEnded { setPaused(!gamePaused) }
        hud.scoreboard.root.isHidden = !input.isDown(KeyCode.tab)
        if input.wasPressed(KeyCode.f1), let view = view {
            view.showsFPS.toggle()
            view.showsNodeCount.toggle()
        }
        guard !gameEnded && !gamePaused else {
            session.player.wantsToFire = false
            return
        }
        playerController.update(input: input, mouseWorld: mouseScene, leftClickAvailable: leftAvailable)
    }
}
