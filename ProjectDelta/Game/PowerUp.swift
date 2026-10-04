import SceneKit

// MARK: - Power-ups

enum PowerUpKind {
    case magnet      // attracts nearby coins for 8s
    case multiplier  // 2x score for 8s
}

/// Floating power-up pickup. Position is its center (scene coordinates).
final class PowerUp: SCNNode {

    let kind: PowerUpKind

    private var baseY: Float?
    private var bobPhase: Double = 0

    init(kind: PowerUpKind) {
        self.kind = kind
        super.init()
        build()
    }

    required init?(coder: NSCoder) { nil }

    private func mat(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.roughness = 0.5
        return m
    }

    private func build() {
        // badge backing
        let badgeColor: UIColor
        switch kind {
        case .magnet: badgeColor = UIColor(red: 0.6, green: 0.3, blue: 0.85, alpha: 1)
        case .multiplier: badgeColor = UIColor(red: 0.2, green: 0.65, blue: 0.35, alpha: 1)
        }
        let badge = SCNNode(geometry: SCNSphere(radius: 0.42))
        badge.geometry?.materials = [mat(badgeColor)]
        badge.scale = SCNVector3(1, 1, 0.45)
        addChildNode(badge)

        switch kind {
        case .magnet:
            // horseshoe magnet: red torus with white tips
            let magnet = SCNTorus(ringRadius: 0.2, pipeRadius: 0.07)
            magnet.materials = [mat(UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1))]
            let mNode = SCNNode(geometry: magnet)
            mNode.position = SCNVector3(0, 0.06, 0.2)
            addChildNode(mNode)
            for x in [-0.2, 0.2] as [Float] {
                let tip = SCNNode(geometry: SCNBox(width: 0.13, height: 0.16, length: 0.06, chamferRadius: 0.02))
                tip.geometry?.materials = [mat(.white)]
                tip.position = SCNVector3(x, -0.18, 0.2)
                addChildNode(tip)
            }
        case .multiplier:
            // gold "2X" text on the badge face
            let text = SCNText(string: "2X", extrusionDepth: 0.06)
            text.font = UIFont.boldSystemFont(ofSize: 0.55)
            text.materials = [mat(.white)]
            let tNode = SCNNode(geometry: text)
            let (minB, maxB) = text.boundingBox
            tNode.pivot = SCNMatrix4MakeTranslation((maxB.x + minB.x) / 2, (maxB.y + minB.y) / 2, 0)
            tNode.position = SCNVector3(0, 0, 0.22)
            addChildNode(tNode)
        }
    }

    /// Called every frame by the scene — gentle bob and turntable spin.
    func spin(_ dt: TimeInterval) {
        if baseY == nil { baseY = position.y }
        bobPhase += dt * 3
        if let baseY {
            position.y = baseY + Float(sin(bobPhase)) * 0.15
        }
        rotation = SCNVector4(0, 1, 0, rotation.w + Float(dt) * 2)
    }
}
