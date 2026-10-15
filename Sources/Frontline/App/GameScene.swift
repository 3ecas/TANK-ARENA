import SpriteKit

/// One battle on screen: runs the session, renderer, camera, HUD and player input.
@MainActor
final class GameScene: SKScene {
    unowned let router: SceneRouter
    let session: GameSession
    let worldRenderer: WorldRenderer
    let hud: HUD
    let cameraController: CameraController
    let playerController: PlayerController
    let audio: AudioDirector
    let fog = FogOfWarRenderer()
    var clock = GameClock()
    var gamePaused = false
    var gameEnded = false
    var mouseScene: CGPoint = .zero

    init(size: CGSize, router: SceneRouter) {
        let session = GameSession()
        self.router = router
        self.session = session
        worldRenderer = WorldRenderer(session: session)
        hud = HUD(session: session)
        cameraController = CameraController(mapSize: session.world.map.size, start: session.player.position)
        playerController = PlayerController(soldier: session.player, weapons: session.weapons,
                                            grenades: session.grenades, melee: session.melee)
        audio = AudioDirector(sound: router.sound, session: session)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addChild(worldRenderer.root)
        addChild(cameraController.node)
        camera = cameraController.node
        cameraController.node.addChild(fog.node)
        cameraController.node.addChild(hud.root)
        let router = self.router
        playerController.onMessage = { [unowned self] message in self.showError(message) }
        hud.pauseMenu.onResume = { [unowned self] in self.setPaused(false) }
        hud.pauseMenu.onMainMenu = { router.showMainMenu() }
        hud.pauseMenu.onQuit = { router.quit() }
        hud.gameOver.onPlayAgain = { router.startGame() }
        hud.gameOver.onMainMenu = { router.showMainMenu() }
        worldRenderer.effects.onBlast = { [unowned self] magnitude, position in
            if self.cameraController.visibleRect.insetBy(dx: -150, dy: -150).contains(position) {
                self.cameraController.shake(magnitude: magnitude, duration: 0.3)
            }
        }
        audio.listener = { [unowned self] in self.cameraController.focus }
        session.bus.subscribe { [unowned self] event in self.handle(event) }
        layoutForSize()
        cameraController.snap(to: session.player.position)
        hud.banner.announce("25 vs 25 — eliminate the red team!", color: UIStyle.accent)
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
        cameraController.update(dt: dt, follow: session.viewer?.position)
        worldRenderer.update(dt: running ? dt : 0)
        fog.update(viewer: session.viewer, cameraCenter: cameraController.node.position, viewSize: size,
                   map: session.world.map)
        let mouseScreen = hud.root.convert(mouseScene, from: self)
        hud.update(dt: dt, cameraRect: cameraController.visibleRect, mouseScreen: mouseScreen, renderer: worldRenderer)
        router.input.endFrame()
    }

    private func handle(_ event: GameEvent) {
        let world = session.world
        switch event {
        case .soldierKilled(let victimId, let killerId, let weaponName):
            if let victim = world.soldier(victimId) {
                hud.killFeed.add(killer: world.soldier(killerId), victim: victim, weapon: weaponName,
                                 playerTeam: session.player.team)
            }
        case .soldierHit(_, let attackerId, _, _):
            if attackerId == session.player.id { hud.crosshair.showHit() }
        case .soldierRespawned(let id):
            if id == session.player.id {
                cameraController.snap(to: session.player.position)
                hud.banner.announce("Respawned — this is your last life", color: Palette.warning)
            }
        case .announcement(let text):
            hud.banner.announce(text, color: UIStyle.accent)
        case .zoneCaptured(let name, let team):
            let ours = team == session.player.team
            hud.banner.announce(ours ? "Zone \(name) captured" : "Zone \(name) lost",
                                color: ours ? Palette.team(team) : Palette.warning)
        case .matchOver(let winner):
            gameEnded = true
            hud.pauseMenu.isVisible = false
            hud.gameOver.show(victory: winner.map { $0 == session.player.team }, player: session.player,
                              time: world.time, score: "\(world.score(.blue)) – \(world.score(.red))")
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
    }
}
