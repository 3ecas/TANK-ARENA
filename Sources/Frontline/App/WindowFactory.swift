import AppKit

/// Creates the resizable game window with native full-screen support (green button / Cmd+F).
@MainActor
enum WindowFactory {
    static func makeWindow(contentView: NSView) -> NSWindow {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = min(1600, screen.width * 0.9)
        let height = min(1000, screen.height * 0.9)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Frontline"
        window.contentView = contentView
        window.contentMinSize = NSSize(width: 1024, height: 640)
        window.collectionBehavior = [.fullScreenPrimary]
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
