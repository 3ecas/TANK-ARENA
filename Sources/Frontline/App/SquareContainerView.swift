import AppKit

/// Window content that keeps the game view square and centred, with black bars on the sides
/// (used in full screen, where the screen itself is not square).
@MainActor
final class SquareContainerView: NSView {
    private let content: NSView

    init(content: NSView) {
        self.content = content
        super.init(frame: content.frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        addSubview(content)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        let side = Swift.min(bounds.width, bounds.height)
        content.frame = NSRect(x: (bounds.width - side) / 2, y: (bounds.height - side) / 2, width: side, height: side)
    }
}
