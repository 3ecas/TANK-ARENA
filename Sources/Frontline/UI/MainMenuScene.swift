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
        let map = ArenaMap(layout: MapLayout.compound())
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
        let subtitle = UIStyle.label("Bomb defusal · 5 vs 5 · one life", size: 18, align: .center)
        subtitle.position = CGPoint(x: 0, y: 148)
        let info = UIStyle.label("Attackers plant the bomb on site A or B (45 s fuse). Defenders stop or defuse it.", size: 13,
                                 color: UIStyle.dimText, align: .center)
        info.position = CGPoint(x: 0, y: 118)

        let modes: [(String, MapKind, Bool)] = [("ATTACK · COMPOUND", .compound, true), ("DEFEND · COMPOUND", .compound, false),
                                                ("ATTACK · CAVES", .caves, true), ("DEFEND · CAVES", .caves, false)]
        var buttons: [SKNode] = []
        for (index, mode) in modes.enumerated() {
            let button = UIButton(title: mode.0, size: CGSize(width: 230, height: 48), fontSize: 17,
                                  color: mode.2 ? UIStyle.buttonOwned : UIStyle.buttonColor)
            button.position = CGPoint(x: index % 2 == 0 ? -122 : 122, y: index < 2 ? 60 : 4)
            let (map, attacking) = (mode.1, mode.2)
            button.onClick = { [unowned self] in self.router.startGame(map: map, attacking: attacking) }
            buttons.append(button)
        }
        let help = UIButton(title: "Controls", size: CGSize(width: 320, height: 42), fontSize: 15)
        help.position = CGPoint(x: 0, y: -58)
        help.onClick = { [unowned self] in self.controls.root.isHidden.toggle() }
        let quit = UIButton(title: "Quit", size: CGSize(width: 320, height: 42), fontSize: 15)
        quit.position = CGPoint(x: 0, y: -110)
        quit.onClick = { [unowned self] in self.router.quit() }
        for node in ([title, subtitle, info, help, quit] as [SKNode]) + buttons { menuLayer.addChild(node) }
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
        "E (hold) ............ plant / defuse the bomb",
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
