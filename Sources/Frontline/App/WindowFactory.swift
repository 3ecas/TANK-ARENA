import AppKit

/// Creates the square game window with native full-screen support (green button / Cmd+F).
/// The game view always stays square; in full screen it is centred with black side bars.
@MainActor
enum WindowFactory {
    static func makeWindow(contentView: NSView) -> NSWindow {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let side = Swift.max(GameConfig.minWindowSide, Swift.min(GameConfig.windowSide, screen.height * 0.92, screen.width * 0.9))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: side, height: side),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Frontline"
        window.contentView = SquareContainerView(content: contentView)
        window.contentAspectRatio = NSSize(width: 1, height: 1)
        window.contentMinSize = NSSize(width: GameConfig.minWindowSide, height: GameConfig.minWindowSide)
        window.collectionBehavior = [.fullScreenPrimary]
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
