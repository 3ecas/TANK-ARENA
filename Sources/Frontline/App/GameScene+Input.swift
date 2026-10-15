import SpriteKit

/// Scene-level keys (Esc, P, Tab, Space, F1) and routing of clicks between HUD and gameplay.
extension GameScene {
    func processInput() {
        let input = router.input
        var leftAvailable = true
        if input.leftPressed && hud.handleClick(scenePoint: mouseScene, scene: self) {
            leftAvailable = false
            input.consumeLeftPress()
        }
        if input.wasPressed(KeyCode.escape) { handleEscape() }
        hud.scoreboard.root.isHidden = !input.isDown(KeyCode.tab)
        guard !gameEnded && !gamePaused else { return }

        if input.wasPressed(KeyCode.p) { toggleShop() }
        if input.wasPressed(KeyCode.space) {
            cameraController.lock()
            cameraController.snap(to: session.player.position)
        }
        if input.wasPressed(KeyCode.f1), let view = view {
            view.showsFPS.toggle()
            view.showsNodeCount.toggle()
        }
        if hud.shop.isOpen {
            if !session.ctx.shop.isAtShop(session.player) { hud.shop.close() }
            leftAvailable = false
        }
        playerController.update(input: input, mouseWorld: mouseScene, leftClickAvailable: leftAvailable)
    }

    private func handleEscape() {
        guard !gameEnded else { return }
        if playerController.aimingSlot != nil {
            playerController.cancelAiming()
        } else if hud.shop.isOpen {
            hud.shop.close()
        } else {
            setPaused(!gamePaused)
        }
    }

    private func toggleShop() {
        if hud.shop.isOpen {
            hud.shop.close()
        } else if session.ctx.shop.isAtShop(session.player) {
            playerController.cancelAiming()
            hud.shop.open()
        } else {
            showError("The shop is only available at base")
        }
    }
}
