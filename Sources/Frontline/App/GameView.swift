import AppKit
import SpriteKit

/// SKView that forwards raw keyboard / mouse input to the `InputManager`
/// and never shows a context menu on right-click.
@MainActor
final class GameView: SKView {
    let input: InputManager
    private var trackingArea: NSTrackingArea?
    /// True while a Ctrl+click (treated as a right click) is held.
    private var controlClick = false

    init(frame: NSRect, input: InputManager) {
        self.input = input
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func menu(for event: NSEvent) -> NSMenu? { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea { removeTrackingArea(existing) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeAlways, .inVisibleRect],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    // MARK: Keyboard

    override func keyDown(with event: NSEvent) {
        input.keyDown(event.keyCode, isRepeat: event.isARepeat)
    }

    override func keyUp(with event: NSEvent) {
        input.keyUp(event.keyCode)
    }

    override func flagsChanged(with event: NSEvent) {}

    // MARK: Mouse

    override func mouseMoved(with event: NSEvent) { input.mouseMoved(to: location(of: event)) }
    override func mouseDragged(with event: NSEvent) { input.mouseMoved(to: location(of: event)) }
    override func rightMouseDragged(with event: NSEvent) { input.mouseMoved(to: location(of: event)) }

    override func mouseDown(with event: NSEvent) {
        // Ctrl+click acts as a right click on trackpads without secondary click.
        if event.modifierFlags.contains(.control) {
            controlClick = true
            input.rightMouse(down: true, at: location(of: event))
        } else {
            input.leftMouse(down: true, at: location(of: event))
        }
    }

    override func mouseUp(with event: NSEvent) {
        if controlClick {
            controlClick = false
            input.rightMouse(down: false, at: location(of: event))
        } else {
            input.leftMouse(down: false, at: location(of: event))
        }
    }

    override func rightMouseDown(with event: NSEvent) { input.rightMouse(down: true, at: location(of: event)) }
    override func rightMouseUp(with event: NSEvent) { input.rightMouse(down: false, at: location(of: event)) }

    private func location(of event: NSEvent) -> CGPoint {
        convert(event.locationInWindow, from: nil)
    }
}
