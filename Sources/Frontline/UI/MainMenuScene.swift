import SpriteKit

/// Title screen: play, difficulty, starting loadout, controls, quit.
@MainActor
final class MainMenuScene: SKScene {
    private unowned let router: SceneRouter
    private var settings: GameSettings
    private let menu = SKNode()
    private let background: SKSpriteNode
    private let difficultyButton = UIButton(title: "", size: CGSize(width: 320, height: 46), fontSize: 16)
    private let loadoutButton = UIButton(title: "", size: CGSize(width: 320, height: 46), fontSize: 16)
    private let loadoutSummary = UIStyle.label("", size: 13, color: UIStyle.dimText, align: .center)
    private let controls = ControlsPanel()
    private var clock = GameClock()
    private var time: CGFloat = 0

    init(size: CGSize, router: SceneRouter, settings: GameSettings) {
        self.router = router
        self.settings = settings
        let map = MapLayout()
        background = SKSpriteNode(texture: MapTextureBuilder.texture(for: map),
                                  size: CGSize(width: map.size, height: map.size))
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        build()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build() {
        background.alpha = 0.45
        background.zPosition = -10
        addChild(background)
        addChild(menu)
        let title = UIStyle.label("FRONTLINE", size: 72, color: UIStyle.accent, bold: true, align: .center)
        title.position = CGPoint(x: 0, y: 220)
        let subtitle = UIStyle.label("3-lane modern warfare MOBA", size: 18, color: UIStyle.textColor, align: .center)
        subtitle.position = CGPoint(x: 0, y: 168)
        menu.addChild(title)
        menu.addChild(subtitle)

        let play = UIButton(title: "PLAY", size: CGSize(width: 320, height: 56), fontSize: 22, color: UIStyle.buttonOwned)
        play.position = CGPoint(x: 0, y: 90)
        play.onClick = { [unowned self] in self.router.startGame(settings: self.settings) }
        difficultyButton.position = CGPoint(x: 0, y: 25)
        difficultyButton.onClick = { [unowned self] in
            self.settings.difficulty = self.settings.difficulty.next
            self.refresh()
        }
        loadoutButton.position = CGPoint(x: 0, y: -35)
        loadoutButton.onClick = { [unowned self] in
            self.settings.loadoutIndex = (self.settings.loadoutIndex + 1) % StartingLoadouts.all.count
            self.refresh()
        }
        loadoutSummary.position = CGPoint(x: 0, y: -68)
        let help = UIButton(title: "Controls", size: CGSize(width: 320, height: 42), fontSize: 15)
        help.position = CGPoint(x: 0, y: -115)
        help.onClick = { [unowned self] in self.controls.root.isHidden.toggle() }
        let quit = UIButton(title: "Quit", size: CGSize(width: 320, height: 42), fontSize: 15)
        quit.position = CGPoint(x: 0, y: -170)
        quit.onClick = { [unowned self] in self.router.quit() }
        for node in [play, difficultyButton, loadoutButton, loadoutSummary, help, quit] as [SKNode] {
            menu.addChild(node)
        }
        controls.root.zPosition = 20
        addChild(controls.root)
        refresh()
    }

    private func refresh() {
        difficultyButton.setTitle("Difficulty: \(settings.difficulty.displayName)")
        let loadout = settings.startingLoadout
        loadoutButton.setTitle("Loadout: \(loadout.name)")
        loadoutSummary.text = loadout.summary
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = clock.tick(currentTime)
        time += dt
        background.position = CGPoint(x: sin(time * 0.05) * 400, y: cos(time * 0.04) * 400)
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
        if input.wasPressed(KeyCode.returnKey) { router.startGame(settings: settings) }
        if input.wasPressed(KeyCode.escape) { controls.root.isHidden = true }
        input.endFrame()
    }
}

/// Controls reference shown from the main menu.
@MainActor
final class ControlsPanel {
    let root = SKNode()
    private let lines = [
        "WASD / arrows ....... move",
        "Mouse ............... aim (soldier faces cursor)",
        "Right mouse ......... lock target & auto-fire (hold: follow cursor)",
        "Left mouse .......... ability slot 1",
        "Q / E / R ........... ability slots 2-4",
        "Hold + release ...... aim area abilities (Esc cancels)",
        "1 2 3 4 ............. spend ability points on a slot",
        "B ................... recall to base",
        "P ................... shop (at base)",
        "Tab ................. scoreboard",
        "Space ............... center camera",
        "Esc ................. pause",
        "Cmd+F ............... full screen",
    ]

    init() {
        root.isHidden = true
        root.addChild(UIStyle.panel(size: CGSize(width: 640, height: 400)))
        let title = UIStyle.label("CONTROLS", size: 22, color: UIStyle.accent, bold: true, align: .center)
        title.position = CGPoint(x: 0, y: 170)
        root.addChild(title)
        for (index, line) in lines.enumerated() {
            let label = UIStyle.label(line, size: 14)
            label.position = CGPoint(x: -290, y: 130 - CGFloat(index) * 24)
            root.addChild(label)
        }
    }
}
