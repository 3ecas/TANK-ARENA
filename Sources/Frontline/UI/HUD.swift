import SpriteKit

/// Screen-space interface attached to the camera. Lays out and updates every HUD element
/// and routes clicks to buttons / minimap.
@MainActor
final class HUD {
    let root = SKNode()
    let status = StatusPanel()
    let topBar = TopBar()
    let abilityBar = AbilityBar()
    let banner = AnnouncementBanner()
    let notices = CenterNotices()
    let minimap: Minimap
    let shop: ShopPanel
    let scoreboard: Scoreboard
    let pauseMenu = PauseMenu()
    let gameOver = GameOverOverlay()
    private unowned let session: GameSession
    /// Called when the minimap is clicked, with the world position.
    var onMinimapClick: ((CGPoint) -> Void)?

    init(session: GameSession) {
        self.session = session
        minimap = Minimap(session: session)
        shop = ShopPanel(session: session)
        scoreboard = Scoreboard(session: session)
        root.zPosition = 100
        let layers: [(SKNode, CGFloat)] = [
            (status.root, 0), (topBar.root, 0), (abilityBar.root, 0), (minimap.root, 0), (notices.root, 1),
            (banner.root, 2), (shop.root, 10), (scoreboard.root, 12), (pauseMenu.root, 20), (gameOver.root, 30),
        ]
        for (node, z) in layers {
            node.zPosition = z
            root.addChild(node)
        }
    }

    func layout(size: CGSize) {
        let halfW = size.width / 2, halfH = size.height / 2
        let statusSize = StatusPanel.size
        status.root.position = CGPoint(x: -halfW + statusSize.width / 2 + 14, y: -halfH + statusSize.height / 2 + 14)
        abilityBar.root.position = CGPoint(x: 0, y: -halfH + AbilitySlotView.side / 2 + 18)
        minimap.root.position = CGPoint(x: halfW - Minimap.side / 2 - 18, y: -halfH + Minimap.side / 2 + 18)
        topBar.root.position = CGPoint(x: 0, y: halfH - 34)
        topBar.layout(screen: size)
        banner.root.position = CGPoint(x: 0, y: halfH - 100)
        banner.messageOffset = -(size.height - 100) + AbilitySlotView.side + 140
        notices.root.position = CGPoint(x: 0, y: -halfH + AbilitySlotView.side + 60)
    }

    func update(dt: CGFloat, cameraRect: CGRect, aimingSlot: Int?, fogTexture: SKTexture?) {
        let player = session.player
        status.update(hero: player)
        topBar.update(session: session)
        let abilities = session.ctx.abilities!
        abilityBar.update(hero: player, aimingSlot: aimingSlot) { def, rank in
            abilities.effectiveCooldown(def, rank: rank, hero: player)
        }
        notices.update(hero: player, aimingSlot: aimingSlot)
        banner.update(dt: dt)
        minimap.update(cameraRect: cameraRect, fogTexture: fogTexture)
        shop.update(dt: dt)
        scoreboard.update()
    }

    /// Handles a left click at a point in scene coordinates. Returns true if the UI consumed it.
    func handleClick(scenePoint: CGPoint, scene: SKScene) -> Bool {
        if let button = UIHitTester.button(at: scenePoint, in: root, scene: scene) {
            button.onClick?()
            return true
        }
        let local = root.convert(scenePoint, from: scene)
        if gameOver.isVisible || pauseMenu.isVisible { return true }
        if shop.isOpen && shop.contains(local) { return true }
        if minimap.contains(local) {
            onMinimapClick?(minimap.worldPoint(for: local))
            return true
        }
        return false
    }

    /// True when a point (scene coordinates) is over an interactive HUD element.
    func isOverUI(scenePoint: CGPoint, scene: SKScene) -> Bool {
        let local = root.convert(scenePoint, from: scene)
        return minimap.contains(local) || (shop.isOpen && shop.contains(local))
    }
}
