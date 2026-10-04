import SpriteKit

// MARK: - Power-ups

enum PowerUpKind {
    case magnet      // attracts nearby coins for 8s
    case multiplier  // 2x score for 8s
}

/// Floating power-up pickup. Position is its center (scene coordinates).
final class PowerUp: SKNode {

    let kind: PowerUpKind

    init(kind: PowerUpKind) {
        self.kind = kind
        super.init()
        build()
        startBob()
    }

    required init?(coder: NSCoder) { nil }

    private func build() {
        let badgeColor: SKColor
        switch kind {
        case .magnet: badgeColor = SKColor(red: 0.6, green: 0.3, blue: 0.85, alpha: 1)
        case .multiplier: badgeColor = SKColor(red: 0.2, green: 0.65, blue: 0.35, alpha: 1)
        }

        let badge = SKShapeNode(circleOfRadius: 26)
        badge.fillColor = badgeColor
        badge.strokeColor = .white
        badge.lineWidth = 3
        badge.isAntialiased = true
        addChild(badge)

        switch kind {
        case .magnet:
            // horseshoe magnet: red arc with white tips
            let arc = SKShapeNode()
            let p = CGMutablePath()
            p.addArc(center: CGPoint(x: 0, y: 4), radius: 11,
                     startAngle: .pi * 0.95, endAngle: .pi * 2.05, clockwise: false)
            arc.path = p
            arc.strokeColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)
            arc.lineWidth = 9
            arc.lineCap = .round
            arc.isAntialiased = true
            addChild(arc)
            for x in [-10.5, 10.5] as [CGFloat] {
                let tip = SKShapeNode(rect: CGRect(x: x - 4, y: -14, width: 8, height: 10), cornerRadius: 2)
                tip.fillColor = .white
                tip.strokeColor = .clear
                tip.isAntialiased = true
                addChild(tip)
            }
        case .multiplier:
            let label = SKLabelNode(text: "2x")
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 22
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: 1)
            addChild(label)
        }
    }

    private func startBob() {
        let up = SKAction.moveBy(x: 0, y: 12, duration: 0.6)
        up.timingMode = .easeInEaseOut
        let down = SKAction.moveBy(x: 0, y: -12, duration: 0.6)
        down.timingMode = .easeInEaseOut
        run(.repeatForever(.sequence([up, down])))
    }
}
