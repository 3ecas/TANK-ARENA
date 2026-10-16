import SpriteKit

/// Screen-space interface attached to the camera.
@MainActor
final class HUD {
    let root = SKNode()
    let vitals = VitalsPanel()
    let weapons = WeaponPanel()
    let ability = AbilityPanel()
    let counter = TeamCounter()
    let killFeed = KillFeed()
    let notices = CenterNotices()
    let bombPrompt = BombPrompt()
    let banner = AnnouncementBanner()
    let crosshair = Crosshair()
    let flash = FlashOverlay()
    let minimap: Minimap
    let scoreboard: Scoreboard
    let pauseMenu = PauseMenu()
    let gameOver = GameOverOverlay()
    private unowned let session: GameSession

    init(session: GameSession) {
        self.session = session
        minimap = Minimap(session: session)
        scoreboard = Scoreboard(session: session)
        root.zPosition = 100
        let layers: [(SKNode, CGFloat)] = [
            (flash.node, 0), (vitals.root, 1), (weapons.root, 1), (ability.root, 1), (counter.root, 1), (killFeed.root, 1),
            (minimap.root, 1), (notices.root, 2), (bombPrompt.root, 2), (banner.root, 2), (crosshair.root, 5), (scoreboard.root, 10),
            (pauseMenu.root, 20), (gameOver.root, 30),
        ]
        for (node, z) in layers {
            node.zPosition = z
            root.addChild(node)
        }
    }

    func layout(size: CGSize) {
        let halfW = size.width / 2, halfH = size.height / 2
        vitals.root.position = CGPoint(x: -halfW + VitalsPanel.size.width / 2 + 14,
                                       y: -halfH + VitalsPanel.size.height / 2 + 14)
        weapons.root.position = CGPoint(x: halfW - WeaponPanel.size.width / 2 - 14,
                                        y: -halfH + WeaponPanel.size.height / 2 + 14)
        counter.root.position = CGPoint(x: 0, y: halfH - 48)
        killFeed.root.position = CGPoint(x: halfW - 16, y: halfH - 24)
        ability.root.position = CGPoint(x: -halfW + AbilityPanel.size.width / 2 + 14,
                                        y: -halfH + VitalsPanel.size.height + AbilityPanel.size.height / 2 + 22)
        if minimap.mapSize.width > Minimap.width {
            // Wide rush minimap: bottom centre, between the vitals and weapon panels.
            minimap.root.position = CGPoint(x: 0, y: -halfH + minimap.mapSize.height / 2 + 18)
        } else {
            minimap.root.position = CGPoint(x: -halfW + minimap.mapSize.width / 2 + 18,
                                            y: halfH - minimap.mapSize.height / 2 - 18)
        }
        banner.root.position = CGPoint(x: 0, y: halfH - 110)
        banner.messageOffset = -(size.height - 110) + 160
    }

    func update(dt: CGFloat, cameraRect: CGRect, mouseScreen: CGPoint, renderer: WorldRenderer) {
        let player = session.player
        vitals.update(soldier: player)
        weapons.update(soldier: player)
        ability.update(soldier: player, world: session.world)
        counter.update(world: session.world, playerTeam: session.player.team)
        killFeed.update(dt: dt)
        notices.update(player: player, spectating: player.isAlive ? nil : session.viewer)
        bombPrompt.update(world: session.world, player: player)
        banner.update(dt: dt)
        flash.update(soldier: player)
        let moving = player.velocity.lengthSquared > 100
        crosshair.root.isHidden = !player.isAlive
        crosshair.update(dt: dt, screenPosition: mouseScreen, spreadScale: moving ? 0.5 : 0.2)
        minimap.update(cameraRect: cameraRect, renderer: renderer)
        scoreboard.update()
    }

    /// Handles a left click at a point in scene coordinates. Returns true if a button consumed it.
    func handleClick(scenePoint: CGPoint, scene: SKScene) -> Bool {
        if let button = UIHitTester.button(at: scenePoint, in: root, scene: scene) {
            button.onClick?()
            return true
        }
        return gameOver.isVisible || pauseMenu.isVisible
    }
}
