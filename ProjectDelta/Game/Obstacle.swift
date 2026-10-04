import SpriteKit

// MARK: - Obstacles

enum ObstacleKind {
    case barrier    // low hurdle — jump over it
    case overhead   // high bar — roll under it
    case train      // full-height block — change lanes
}

/// An obstacle node. Position is the ground-center of its lane (scene coordinates).
final class Obstacle: SKNode {

    let kind: ObstacleKind
    let laneIndex: Int

    init(kind: ObstacleKind, laneIndex: Int) {
        self.kind = kind
        self.laneIndex = laneIndex
        super.init()
        build()
    }

    required init?(coder: NSCoder) { nil }

    /// Scene-space collision rectangle.
    var collisionRect: CGRect {
        switch kind {
        case .barrier:
            return CGRect(x: position.x - 45, y: position.y, width: 90, height: 45)
        case .overhead:
            return CGRect(x: position.x - 50, y: position.y + 55, width: 100, height: 85)
        case .train:
            return CGRect(x: position.x - 55, y: position.y, width: 110, height: 210)
        }
    }

    // MARK: - Art

    private func build() {
        switch kind {
        case .barrier: buildBarrier()
        case .overhead: buildOverhead()
        case .train: buildTrain()
        }
    }

    private func shape(path: CGPath, fill: SKColor, stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        let s = SKShapeNode(path: path)
        s.fillColor = fill
        s.strokeColor = stroke
        s.lineWidth = lineWidth
        s.isAntialiased = true
        return s
    }

    private func rect(_ r: CGRect, fill: SKColor) -> SKShapeNode {
        shape(path: CGPath(rect: r, transform: nil), fill: fill)
    }

    /// Low striped hurdle.
    private func buildBarrier() {
        // posts
        addChild(rect(CGRect(x: -43, y: 0, width: 10, height: 44), fill: SKColor(white: 0.25, alpha: 1)))
        addChild(rect(CGRect(x: 33, y: 0, width: 10, height: 44), fill: SKColor(white: 0.25, alpha: 1)))
        // striped board: alternating orange / white segments
        let boardY: CGFloat = 20
        let boardH: CGFloat = 22
        let segs = 6
        let segW: CGFloat = 90 / CGFloat(segs)
        for i in 0..<segs {
            let c: SKColor = (i % 2 == 0) ? SKColor(red: 0.95, green: 0.45, blue: 0.1, alpha: 1)
                                           : SKColor(white: 0.92, alpha: 1)
            addChild(rect(CGRect(x: -45 + CGFloat(i) * segW, y: boardY, width: segW, height: boardH), fill: c))
        }
        // board outline
        let outline = SKShapeNode(rect: CGRect(x: -45, y: boardY, width: 90, height: boardH))
        outline.fillColor = .clear
        outline.strokeColor = SKColor(white: 0.1, alpha: 1)
        outline.lineWidth = 3
        outline.isAntialiased = true
        addChild(outline)
    }

    /// High bar with supports — roll under it.
    private func buildOverhead() {
        // support posts
        addChild(rect(CGRect(x: -52, y: 0, width: 8, height: 140), fill: SKColor(white: 0.3, alpha: 1)))
        addChild(rect(CGRect(x: 44, y: 0, width: 8, height: 140), fill: SKColor(white: 0.3, alpha: 1)))
        // hazard-striped bar from y=120..142
        let barY: CGFloat = 120
        let barH: CGFloat = 22
        let segs = 7
        let segW: CGFloat = 104 / CGFloat(segs)
        for i in 0..<segs {
            let c: SKColor = (i % 2 == 0) ? SKColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 1)
                                           : SKColor(white: 0.12, alpha: 1)
            addChild(rect(CGRect(x: -52 + CGFloat(i) * segW, y: barY, width: segW, height: barH), fill: c))
        }
        let outline = SKShapeNode(rect: CGRect(x: -52, y: barY, width: 104, height: barH))
        outline.fillColor = .clear
        outline.strokeColor = SKColor(white: 0.1, alpha: 1)
        outline.lineWidth = 3
        outline.isAntialiased = true
        addChild(outline)
        // hanging sign
        let sign = SKShapeNode(rect: CGRect(x: -20, y: barY - 26, width: 40, height: 24), cornerRadius: 4)
        sign.fillColor = SKColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1)
        sign.strokeColor = .clear
        sign.isAntialiased = true
        addChild(sign)
    }

    /// Subway car front — full block, must change lanes.
    private func buildTrain() {
        let bodyW: CGFloat = 110
        let bodyH: CGFloat = 200
        // car body
        let bodyPath = CGPath(roundedRect: CGRect(x: -bodyW / 2, y: 0, width: bodyW, height: bodyH),
                              cornerWidth: 14, cornerHeight: 14, transform: nil)
        addChild(shape(path: bodyPath, fill: SKColor(red: 0.16, green: 0.35, blue: 0.45, alpha: 1),
                       stroke: SKColor(white: 0.08, alpha: 1), lineWidth: 4))
        // roof
        addChild(rect(CGRect(x: -bodyW / 2, y: bodyH - 26, width: bodyW, height: 26),
                      fill: SKColor(white: 0.18, alpha: 1)))
        // pantograph hint
        let pant = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -24, y: bodyH))
        p.addLine(to: CGPoint(x: 0, y: bodyH + 26))
        p.addLine(to: CGPoint(x: 24, y: bodyH))
        pant.path = p
        pant.strokeColor = SKColor(white: 0.25, alpha: 1)
        pant.lineWidth = 5
        pant.isAntialiased = true
        addChild(pant)
        // windshield
        addChild(rect(CGRect(x: -38, y: 128, width: 76, height: 44),
                      fill: SKColor(red: 0.65, green: 0.85, blue: 0.95, alpha: 1)))
        let shieldOutline = SKShapeNode(rect: CGRect(x: -38, y: 128, width: 76, height: 44))
        shieldOutline.fillColor = .clear
        shieldOutline.strokeColor = SKColor(white: 0.1, alpha: 1)
        shieldOutline.lineWidth = 4
        shieldOutline.isAntialiased = true
        addChild(shieldOutline)
        // headlights
        for x in [-30, 30] as [CGFloat] {
            let lamp = SKShapeNode(circleOfRadius: 9)
            lamp.position = CGPoint(x: x, y: 84)
            lamp.fillColor = SKColor(red: 1, green: 0.9, blue: 0.5, alpha: 1)
            lamp.strokeColor = .clear
            lamp.isAntialiased = true
            addChild(lamp)
        }
        // bumper stripe
        addChild(rect(CGRect(x: -bodyW / 2 + 6, y: 34, width: bodyW - 12, height: 12),
                      fill: SKColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1)))
        // "DELTA" plate
        let plate = SKShapeNode(rect: CGRect(x: -30, y: 8, width: 60, height: 20), cornerRadius: 4)
        plate.fillColor = SKColor(white: 0.1, alpha: 1)
        plate.strokeColor = .clear
        plate.isAntialiased = true
        addChild(plate)
        let label = SKLabelNode(text: "D")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 14
        label.fontColor = SKColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 18)
        addChild(label)
    }
}
