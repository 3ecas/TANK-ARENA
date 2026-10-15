import Foundation
import SpriteKit

/// Darkens everything the player's team cannot currently see.
@MainActor
final class FogRenderer {
    let node: SKSpriteNode
    private unowned let session: GameSession
    private var lastRevision = -1
    private let fogAlpha: UInt8 = 150

    init(session: GameSession) {
        self.session = session
        let size = CGSize(width: session.world.map.size, height: session.world.map.size)
        node = SKSpriteNode(color: .black, size: size)
        node.anchorPoint = .zero
        node.alpha = 1
        update()
    }

    func update() {
        let vision = session.ctx.vision
        guard vision.revision != lastRevision else { return }
        lastRevision = vision.revision
        guard let texture = makeTexture(vision.grid(for: session.player.team)) else { return }
        node.texture = texture
        node.color = .white
        node.colorBlendFactor = 0
    }

    private func makeTexture(_ grid: VisionGrid) -> SKTexture? {
        let columns = grid.columns
        var bytes = [UInt8](repeating: 0, count: columns * columns * 4)
        for row in 0..<columns {
            let memoryRow = columns - 1 - row   // image rows are stored top-down
            for column in 0..<columns where !grid.isVisible(column: column, row: row) {
                bytes[(memoryRow * columns + column) * 4 + 3] = fogAlpha
            }
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: columns, height: columns, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: columns * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true,
                                  intent: .defaultIntent) else { return nil }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return texture
    }
}
