import Foundation
import SpriteKit

/// Shared fonts, colours and small node builders for the interface.
@MainActor
enum UIStyle {
    static let font = "Menlo"
    static let boldFont = "Menlo-Bold"
    static let panelColor = SKColor(red: 0.07, green: 0.09, blue: 0.08, alpha: 0.9)
    static let panelBorder = SKColor(red: 0.42, green: 0.52, blue: 0.38, alpha: 1)
    static let buttonColor = SKColor(red: 0.18, green: 0.24, blue: 0.18, alpha: 1)
    static let buttonOwned = SKColor(red: 0.16, green: 0.34, blue: 0.22, alpha: 1)
    static let buttonHighlight = SKColor(red: 0.34, green: 0.44, blue: 0.3, alpha: 1)
    static let buttonDisabled = SKColor(white: 0.22, alpha: 1)
    static let accent = SKColor(red: 0.92, green: 0.8, blue: 0.4, alpha: 1)
    static let textColor = SKColor(white: 0.93, alpha: 1)
    static let dimText = SKColor(white: 0.6, alpha: 1)

    static func label(_ text: String, size: CGFloat, color: SKColor = textColor, bold: Bool = false,
                      align: SKLabelHorizontalAlignmentMode = .left) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: bold ? boldFont : font)
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = align
        label.verticalAlignmentMode = .center
        return label
    }

    static func panel(size: CGSize, color: SKColor = panelColor, border: SKColor = panelBorder) -> SKShapeNode {
        let shape = SKShapeNode(rectOf: size, cornerRadius: 8)
        shape.fillColor = color
        shape.strokeColor = border
        shape.lineWidth = 2
        return shape
    }

    /// Plain rectangle sprite (cheap, no outline).
    static func rect(size: CGSize, color: SKColor) -> SKSpriteNode {
        SKSpriteNode(color: color, size: size)
    }

    /// Greedy word wrap into lines of at most `width` characters.
    static func wrap(_ text: String, width: Int) -> [String] {
        var lines: [String] = []
        var current = ""
        for word in text.split(separator: " ") {
            if current.isEmpty {
                current = String(word)
            } else if current.count + 1 + word.count <= width {
                current += " " + word
            } else {
                lines.append(current)
                current = String(word)
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    static func formatTime(_ seconds: CGFloat) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
