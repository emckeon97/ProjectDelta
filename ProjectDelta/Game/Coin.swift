import SpriteKit

/// Spinning gold coin pickup.
final class Coin: SKNode {

    private static let gold = SKColor(red: 0.96, green: 0.76, blue: 0.26, alpha: 1)
    private static let goldDark = SKColor(red: 0.78, green: 0.55, blue: 0.14, alpha: 1)
    private static let goldLight = SKColor(red: 1.0, green: 0.9, blue: 0.55, alpha: 1)

    override init() {
        super.init()
        build()
        startSpin()
    }

    required init?(coder: NSCoder) { nil }

    private func build() {
        let outer = SKShapeNode(circleOfRadius: 16)
        outer.fillColor = Coin.gold
        outer.strokeColor = Coin.goldDark
        outer.lineWidth = 3
        outer.isAntialiased = true
        addChild(outer)

        let inner = SKShapeNode(circleOfRadius: 10)
        inner.fillColor = Coin.goldLight
        inner.strokeColor = .clear
        inner.isAntialiased = true
        addChild(inner)

        // "D" for Delta stamped in the middle
        let label = SKLabelNode(text: "D")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 14
        label.fontColor = Coin.goldDark
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 1)
        addChild(label)
    }

    private func startSpin() {
        let squash = SKAction.scaleX(to: 0.15, duration: 0.28)
        let stretch = SKAction.scaleX(to: 1.0, duration: 0.28)
        run(.repeatForever(.sequence([squash, stretch])))
    }
}
