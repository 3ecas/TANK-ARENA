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

    init(size: CGSize, router: SceneRouter, mode: GameMode, attacking: Bool, playerClass: SoldierClass) {
        let session = GameSession(mode: mode, playerAttacks: attacking, playerClass: playerClass)
        self.router = router
        self.session = session
        worldRenderer = WorldRenderer(session: session)
        hud = HUD(session: session)
        cameraController = CameraController(mapSize: session.world.map.size, start: session.player.position)
        playerController = PlayerController(soldier: session.player, weapons: session.weapons,
                                            grenades: session.grenades, melee: session.melee)
        audio = AudioDirector(sound: router.sound, session: session)
        // Fixed-size scene scaled to the window: resizing never changes how much of the battlefield you see.
        super.init(size: GameConfig.viewSize)
        scaleMode = .aspectFit
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
        let attacking = session.world.attackers == session.player.team
        let intro: String
        switch session.world.mode {
        case .bomb: intro = attacking ? "ATTACK — plant the bomb on site A or B!" : "DEFEND — stop the bomb!"
        case .rush: intro = attacking ? "RUSH ATTACK — destroy the stations of 5 sectors!" : "RUSH DEFEND — hold all 5 sectors!"
        }
        hud.banner.announce(intro, color: UIStyle.accent)
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
        cameraController.update(dt: dt, follow: cameraTarget())
        worldRenderer.update(dt: running ? dt : 0)
        let flying = session.viewer.flatMap { session.world.vehicle(of: $0) }?.flies == true
        fog.update(viewer: session.viewer, cameraCenter: cameraController.node.position, viewSize: size,
                   map: session.world.map, flying: flying)
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
                hud.banner.announce("Respawned", color: UIStyle.accent)
            }
        case .announcement(let text):
            hud.banner.announce(text, color: UIStyle.accent)
        case .bombPickedUp(let id):
            if world.attackers == session.player.team, let carrier = world.soldier(id) {
                hud.banner.announce(carrier.isPlayer ? "You picked up the bomb" : "\(carrier.name) has the bomb",
                                    color: UIStyle.accent)
            }
        case .bombDropped:
            if world.attackers == session.player.team {
                hud.banner.announce("The bomb has been dropped!", color: Palette.warning)
            }
        case .vehicleHit(_, let attackerId):
            if attackerId == session.player.id { hud.crosshair.showHit() }
        case .rewardEarned(let id, let kind):
            if id == session.player.id {
                let hint = world.vehiclesAllowed ? "press Q to call it in" : "usable in sectors 3–5"
                hud.banner.announce("\(kind.displayName.uppercased()) earned — \(hint)", color: Palette.heal)
            }
        case .vehicleCalled(let id, let kind):
            if let caller = world.soldier(id), caller.team == session.player.team {
                hud.banner.announce(caller.isPlayer ? "You're in the \(kind.displayName.lowercased()) — WASD drive, mouse aim, click fire"
                                                    : "\(caller.name) called in a \(kind.displayName.lowercased())",
                                    color: Palette.team(caller.team))
            }
        case .vehicleDestroyed(_, let position):
            if cameraController.visibleRect.insetBy(dx: -200, dy: -200).contains(position) {
                cameraController.shake(magnitude: 14, duration: 0.5)
            }
        case .abilityFailed(let id, let reason):
            if id == session.player.id { showError(reason) }
        case .abilityUsed(let id, let name):
            if id == session.player.id { hud.banner.showMessage(name) }
        case .soldierRevived(let id, let byId):
            if id == session.player.id {
                cameraController.snap(to: session.player.position)
                hud.banner.announce("Revived by \(world.soldier(byId)?.name ?? "a medic")", color: Palette.heal)
            } else if byId == session.player.id {
                hud.banner.announce("You revived \(world.soldier(id)?.name ?? "a teammate")", color: Palette.heal)
            }
        case .bombExploded:
            cameraController.shake(magnitude: 22, duration: 0.8)
        case .matchOver(let winner):
            gameEnded = true
            hud.pauseMenu.isVisible = false
            let attacking = world.attackers == session.player.team
            hud.gameOver.show(victory: winner.map { $0 == session.player.team }, player: session.player,
                              time: world.time, score: "\(attacking ? "Attack" : "Defence") · \(MatchSummary.reason(world))")
        default:
            break
        }
    }

    /// The camera leans from the player toward the mouse, up to a fixed look-ahead limit.
    private func cameraTarget() -> CGPoint? {
        guard let viewer = session.viewer else { return nil }
        guard viewer === session.player, viewer.isAlive else { return viewer.position }
        let lean = (mouseScene - viewer.position) * GameConfig.cameraLookAheadFraction
        return viewer.position + lean.clampedLength(GameConfig.cameraLookAhead)
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
