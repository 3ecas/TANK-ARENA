import SpriteKit

/// Title screen: play, controls, quit.
@MainActor
final class MainMenuScene: SKScene {
    private unowned let router: SceneRouter
    private let menuLayer = SKNode()
    private let background: SKSpriteNode
    private let controls = ControlsPanel()
    private var clock = GameClock()
    private var time: CGFloat = 0

    init(size: CGSize, router: SceneRouter) {
        self.router = router
        let map = ArenaMap(layout: MapLayout.city())
        background = SKSpriteNode(texture: ArenaPainter.texture(for: map),
                                  size: CGSize(width: map.size.width * 1.4, height: map.size.height * 1.4))
        super.init(size: GameConfig.viewSize)
        scaleMode = .aspectFit
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        build()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build() {
        background.alpha = 0.4
        background.zPosition = -10
        addChild(background)
        addChild(menuLayer)
        let title = UIStyle.label("FRONTLINE", size: 72, color: UIStyle.accent, bold: true, align: .center)
        title.position = CGPoint(x: 0, y: 200)
        let subtitle = UIStyle.label("25 vs 25 close-quarters battle", size: 18, align: .center)
        subtitle.position = CGPoint(x: 0, y: 148)
        let info = UIStyle.label("Primary weapon · pistol · one grenade · knife. 100 HP. One respawn.", size: 13,
                                 color: UIStyle.dimText, align: .center)
        info.position = CGPoint(x: 0, y: 118)

        let play = UIButton(title: "PLAY · CITY", size: CGSize(width: 320, height: 50), fontSize: 20,
                            color: UIStyle.buttonOwned)
        play.position = CGPoint(x: 0, y: 60)
        play.onClick = { [unowned self] in self.router.startGame(map: .city) }
        let caves = UIButton(title: "PLAY · CAVES", size: CGSize(width: 320, height: 50), fontSize: 20,
                             color: UIStyle.buttonOwned)
        caves.position = CGPoint(x: 0, y: 2)
        caves.onClick = { [unowned self] in self.router.startGame(map: .caves) }
        let help = UIButton(title: "Controls", size: CGSize(width: 320, height: 42), fontSize: 15)
        help.position = CGPoint(x: 0, y: -58)
        help.onClick = { [unowned self] in self.controls.root.isHidden.toggle() }
        let quit = UIButton(title: "Quit", size: CGSize(width: 320, height: 42), fontSize: 15)
        quit.position = CGPoint(x: 0, y: -110)
        quit.onClick = { [unowned self] in self.router.quit() }
        for node in [title, subtitle, info, play, caves, help, quit] as [SKNode] { menuLayer.addChild(node) }
        controls.root.zPosition = 20
        addChild(controls.root)
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = clock.tick(currentTime)
        time += dt
        background.position = CGPoint(x: sin(time * 0.05) * 300, y: cos(time * 0.04) * 200)
        let input = router.input
        if input.leftPressed {
            let point = convertPoint(fromView: input.mouseViewPosition)
            if let button = UIHitTester.button(at: point, in: self, scene: self) {
                button.onClick?()
                router.sound.play(.click, volume: 0.6)
            } else if !controls.root.isHidden {
                controls.root.isHidden = true
            }
        }
        if input.wasPressed(KeyCode.returnKey) { router.startGame() }
        if input.wasPressed(KeyCode.escape) { controls.root.isHidden = true }
        input.endFrame()
    }
}

/// Controls reference shown from the main menu.
@MainActor
final class ControlsPanel {
    let root = SKNode()
    private let lines = [
        "W A S D ............. move",
        "Mouse ............... aim (soldier faces the cursor)",
        "Left mouse .......... shoot (hold for automatic weapons)",
        "R ................... reload",
        "1 / 2 / Q ........... primary / pistol / swap",
        "G ................... throw grenade at cursor",
        "F ................... knife (backstab = kill)",
        "Tab ................. scoreboard",
        "Esc ................. pause  ·  Cmd+F full screen",
    ]

    init() {
        root.isHidden = true
        root.addChild(UIStyle.panel(size: CGSize(width: 640, height: 330)))
        let title = UIStyle.label("CONTROLS", size: 22, color: UIStyle.accent, bold: true, align: .center)
        title.position = CGPoint(x: 0, y: 135)
        root.addChild(title)
        for (index, line) in lines.enumerated() {
            let label = UIStyle.label(line, size: 14)
            label.position = CGPoint(x: -290, y: 98 - CGFloat(index) * 24)
            root.addChild(label)
        }
    }
}
