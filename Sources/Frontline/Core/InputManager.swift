import CoreGraphics

/// Collects keyboard and mouse state between frames.
/// The view forwards raw events; scenes read the state once per frame and call `endFrame()`.
@MainActor
final class InputManager {
    private(set) var keysDown = Set<UInt16>()
    private var pressed = Set<UInt16>()
    private var released = Set<UInt16>()

    /// Mouse position in view coordinates (origin bottom-left).
    private(set) var mouseViewPosition: CGPoint = .zero
    private(set) var leftDown = false
    private(set) var rightDown = false
    private(set) var leftPressed = false
    private(set) var leftReleased = false
    private(set) var rightPressed = false
    private(set) var rightReleased = false

    // MARK: Event entry points (called by GameView)

    func keyDown(_ code: UInt16, isRepeat: Bool) {
        if isRepeat { return }
        keysDown.insert(code)
        pressed.insert(code)
    }

    func keyUp(_ code: UInt16) {
        keysDown.remove(code)
        released.insert(code)
    }

    func mouseMoved(to point: CGPoint) {
        mouseViewPosition = point
    }

    func leftMouse(down: Bool, at point: CGPoint) {
        mouseViewPosition = point
        if down { leftDown = true; leftPressed = true } else { leftDown = false; leftReleased = true }
    }

    func rightMouse(down: Bool, at point: CGPoint) {
        mouseViewPosition = point
        if down { rightDown = true; rightPressed = true } else { rightDown = false; rightReleased = true }
    }

    /// Releases everything (e.g. when the window loses focus).
    func reset() {
        for key in keysDown { released.insert(key) }
        keysDown.removeAll()
        if leftDown { leftReleased = true }
        if rightDown { rightReleased = true }
        leftDown = false
        rightDown = false
    }

    // MARK: Queries

    func isDown(_ code: UInt16) -> Bool { keysDown.contains(code) }
    func wasPressed(_ code: UInt16) -> Bool { pressed.contains(code) }
    func wasReleased(_ code: UInt16) -> Bool { released.contains(code) }

    /// Consumes a pending left click so it is not processed twice (e.g. by UI and gameplay).
    func consumeLeftPress() { leftPressed = false }

    func endFrame() {
        pressed.removeAll(keepingCapacity: true)
        released.removeAll(keepingCapacity: true)
        leftPressed = false
        leftReleased = false
        rightPressed = false
        rightReleased = false
    }
}
