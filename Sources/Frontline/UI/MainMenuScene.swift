import SpriteKit

/// Title screen: play, controls, quit.
@MainActor
final class MainMenuScene: SKScene {
    private unowned let router: SceneRouter
    private let menuLayer = SKNode()
    private let background: SKSpriteNode
    private let controls = ControlsPanel()
    private var classButtons: [UIButton] = []
    private var clock = GameClock()
    private var time: CGFloat = 0

    init(size: CGSize, router: SceneRouter) {
        self.router = router
        let map = ArenaMap(layout: MapLayout.office())
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
        let subtitle = UIStyle.label("Bomb or Rush · random side · pick a class", size: 18, align: .center)
        subtitle.position = CGPoint(x: 0, y: 148)
        let info = UIStyle.label("Bomb: 5v5 office, one life.  Rush: 16v16 over 5 sectors, vehicles from killstreaks.", size: 13,
                                 color: UIStyle.dimText, align: .center)
        info.position = CGPoint(x: 0, y: 118)

        let modes: [(GameMode, String)] = [(.bomb, "BOMB · 5 vs 5"), (.rush, "RUSH · 16 vs 16")]
        var buttons: [SKNode] = []
        for (index, entry) in modes.enumerated() {
            let button = UIButton(title: entry.1, size: CGSize(width: 320, height: 52), fontSize: 20,
                                  color: UIStyle.buttonOwned)
            button.position = CGPoint(x: 0, y: 64 - CGFloat(index) * 60)
            let mode = entry.0
            button.onClick = { [unowned self] in self.router.startGame(mode: mode) }
            buttons.append(button)
        }
        // Class picker: three toggles, the chosen one highlighted.
        classButtons.removeAll()
        for (index, soldierClass) in SoldierClass.allCases.enumerated() {
            let button = UIButton(title: soldierClass.displayName.uppercased(), size: CGSize(width: 150, height: 40), fontSize: 14)
            button.position = CGPoint(x: CGFloat(index - 1) * 160, y: -66)
            button.isSelected = soldierClass == router.playerClass
            classButtons.append(button)
        }
        for (button, soldierClass) in zip(classButtons, SoldierClass.allCases) {
            button.onClick = { [unowned self] in
                self.router.playerClass = soldierClass
                for (other, otherClass) in zip(self.classButtons, SoldierClass.allCases) { other.isSelected = otherClass == soldierClass }
            }
            buttons.append(button)
        }
        let help = UIButton(title: "Controls", size: CGSize(width: 320, height: 42), fontSize: 15)
        help.position = CGPoint(x: 0, y: -124)
        help.onClick = { [unowned self] in self.controls.root.isHidden.toggle() }
        let quit = UIButton(title: "Quit", size: CGSize(width: 320, height: 42), fontSize: 15)
        quit.position = CGPoint(x: 0, y: -174)
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
        "1 / 2 / 3 ........... primary / pistol / RPG (engineer)",
        "G ................... throw grenade at cursor",
        "F ................... knife (backstab = kill)",
        "Q ................... class ability / call in vehicle",
        "E (hold) ............ plant · arm · defuse · revive",
        "Tab ................. scoreboard",
        "Esc ................. pause  ·  Cmd+F full screen",
    ]

    init() {
        root.isHidden = true
        root.addChild(UIStyle.panel(size: CGSize(width: 640, height: 350)))
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
