import AppKit
import SpriteKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private var router: SceneRouter?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MenuBuilder.makeMainMenu()
        NSApp.applicationIconImage = IconGenerator.makeImage(size: 512)

        let input = InputManager()
        let view = GameView(frame: NSRect(x: 0, y: 0, width: 1440, height: 900), input: input)
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.showsFPS = false

        let window = WindowFactory.makeWindow(contentView: view)
        window.delegate = self
        self.window = window

        let router = SceneRouter(view: view, input: input)
        self.router = router
        router.showMainMenu()

        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func windowDidResignKey(_ notification: Notification) {
        router?.input.reset()
    }
}
