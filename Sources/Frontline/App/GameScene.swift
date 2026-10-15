import SpriteKit

/// One match on screen: runs the session, renderer, camera, HUD and player input.
@MainActor
final class GameScene: SKScene {
    unowned let router: SceneRouter
    let session: GameSession
    let worldRenderer: WorldRenderer
    let hud: HUD
    let cameraController: CameraController
    let playerController: PlayerController
    let targeting = TargetingOverlay()
    let audio: AudioDirector
    var clock = GameClock()
    var gamePaused = false
    var gameEnded = false
    var mouseScene: CGPoint = .zero

    init(size: CGSize, router: SceneRouter, settings: GameSettings) {
        let session = GameSession(settings: settings)
        self.router = router
        self.session = session
        worldRenderer = WorldRenderer(session: session)
        hud = HUD(session: session)
        cameraController = CameraController(mapSize: session.world.map.size, start: session.player.position)
        playerController = PlayerController(hero: session.player, ctx: session.ctx)
        audio = AudioDirector(sound: router.sound, session: session)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.08, green: 0.1, blue: 0.07, alpha: 1)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addChild(worldRenderer.root)
        worldRenderer.overlayLayer.addChild(targeting.root)
        addChild(cameraController.node)
        camera = cameraController.node
        cameraController.node.addChild(hud.root)
        wireCallbacks()
        layoutForSize()
        cameraController.snap(to: session.player.position)
        hud.banner.announce("Destroy the enemy HQ!", color: UIStyle.accent)
    }

    private func wireCallbacks() {
        let router = self.router
        playerController.onMessage = { [unowned self] message in self.showError(message) }
        playerController.onMoveOrder = { [unowned self] point in self.targeting.showMoveMarker(at: point) }
        hud.onMinimapClick = { [unowned self] point in self.cameraController.moveTo(point) }
        hud.shop.onResult = { result in if !result.isSuccess { router.sound.play(.error, volume: 0.6) } }
        hud.pauseMenu.onResume = { [unowned self] in self.setPaused(false) }
        hud.pauseMenu.onMainMenu = { router.showMainMenu() }
        hud.pauseMenu.onQuit = { router.quit() }
        hud.gameOver.onPlayAgain = { [unowned self] in router.startGame(settings: self.session.settings) }
        hud.gameOver.onMainMenu = { router.showMainMenu() }
        worldRenderer.effects.onBigExplosion = { [unowned self] magnitude, position in
            if self.cameraController.visibleRect.insetBy(dx: -200, dy: -200).contains(position) {
                self.cameraController.shake(magnitude: magnitude, duration: 0.35)
            }
        }
        audio.listener = { [unowned self] in self.cameraController.focus }
        session.bus.subscribe { [unowned self] event in self.handle(event) }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForSize()
    }

    private func layoutForSize() {
        cameraController.viewSize = size
        hud.layout(size: size)
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = clock.tick(currentTime)
        mouseScene = convertPoint(fromView: router.input.mouseViewPosition)
        processInput()
        let running = !gamePaused && !gameEnded
        if running { session.update(dt: dt) }
        let player = session.player
        cameraController.update(dt: dt, follow: player.isAlive ? player.position : nil)
        worldRenderer.update(dt: running ? dt : 0)
        updateTargeting(dt: dt)
        hud.update(dt: dt, cameraRect: cameraController.visibleRect, aimingSlot: playerController.aimingSlot,
                   fogTexture: worldRenderer.fogTexture)
        router.input.endFrame()
    }

    private func updateTargeting(dt: CGFloat) {
        let player = session.player
        let aiming = playerController.aimingSlot
            .flatMap { player.loadout.ability(inSlot: $0) }
            .map { AbilityCatalog.def($0) }
        targeting.update(dt: dt, player: player, target: session.world.entity(player.targetId),
                         showRange: playerController.aimingSlot == nil && player.chasesTarget, aiming: aiming,
                         mouse: mouseScene)
    }

    private func handle(_ event: GameEvent) {
        let player = session.player
        switch event {
        case .announcement(let text, let team):
            let color = team.map { $0 == player.team ? Palette.team(.blue) : Palette.team(.red) } ?? UIStyle.accent
            hud.banner.announce(text, color: color)
        case .gameOver(let winner):
            gameEnded = true
            playerController.cancelAiming()
            hud.shop.close()
            hud.pauseMenu.isVisible = false
            hud.gameOver.show(victory: winner == player.team, player: player, time: session.world.time)
        case .heroRespawned(let heroId), .recallCompleted(let heroId):
            if heroId == player.id {
                cameraController.lock()
                cameraController.snap(to: player.position)
            }
        case .strikeIncoming(let team, let position):
            if team != player.team && position.distance(to: player.position) < 900 {
                hud.banner.showMessage("⚠ INCOMING STRIKE")
            }
        default:
            break
        }
    }

    func showError(_ message: String) {
        hud.banner.showMessage(message)
        router.sound.play(.error, volume: 0.5)
    }

    func setPaused(_ paused: Bool) {
        gamePaused = paused
        hud.pauseMenu.isVisible = paused
        playerController.cancelAiming()
    }
}
