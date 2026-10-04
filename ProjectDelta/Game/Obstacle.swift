import SceneKit

// MARK: - Obstacles

enum ObstacleKind {
    case barrier    // low hurdle — jump over it
    case overhead   // high bar — roll under it
    case train      // full-height block — change lanes
}

/// An obstacle node. Position is the ground-center of its lane (scene coordinates).
/// The player runs toward +z, so obstacle fronts face +z.
final class Obstacle: SCNNode {

    let kind: ObstacleKind
    let laneIndex: Int

    init(kind: ObstacleKind, laneIndex: Int) {
        self.kind = kind
        self.laneIndex = laneIndex
        super.init()
        build()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Art helpers

    private func mat(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.roughness.contents = 0.7
        return m
    }

    private func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, color: UIColor, _ x: Float, _ y: Float, _ z: Float = 0) -> SCNNode {
        let n = SCNNode(geometry: SCNBox(width: w, height: h, length: d, chamferRadius: 0.02))
        n.geometry?.materials = [mat(color)]
        n.position = SCNVector3(x, y, z)
        addChildNode(n)
        return n
    }

    private func sphere(_ r: CGFloat, color: UIColor, _ x: Float, _ y: Float, _ z: Float) -> SCNNode {
        let n = SCNNode(geometry: SCNSphere(radius: r))
        n.geometry?.materials = [mat(color)]
        n.position = SCNVector3(x, y, z)
        addChildNode(n)
        return n
    }

    private func build() {
        switch kind {
        case .barrier: buildBarrier()
        case .overhead: buildOverhead()
        case .train: buildTrain()
        }
    }

    /// Low striped hurdle (top at y≈1.0).
    private func buildBarrier() {
        let dark = UIColor(white: 0.25, alpha: 1)
        box(0.15, 0.9, 0.15, color: dark, -0.85, 0.45)
        box(0.15, 0.9, 0.15, color: dark, 0.85, 0.45)
        // striped board: alternating orange / white segments
        let segs = 6
        let segW: CGFloat = 1.8 / CGFloat(segs)
        for i in 0..<segs {
            let c: UIColor = (i % 2 == 0) ? UIColor(red: 0.95, green: 0.45, blue: 0.1, alpha: 1)
                                           : UIColor(white: 0.92, alpha: 1)
            box(segW, 0.42, 0.12, color: c, Float(-0.9 + Double(i) * Double(segW) + Double(segW) / 2), 0.69)
        }
    }

    /// High bar with supports (bar spans y 1.7–2.1) — roll under it.
    private func buildOverhead() {
        let post = UIColor(white: 0.3, alpha: 1)
        box(0.15, 2.6, 0.15, color: post, -1.0, 1.3)
        box(0.15, 2.6, 0.15, color: post, 1.0, 1.3)
        // hazard-striped bar
        let segs = 7
        let segW: CGFloat = 2.0 / CGFloat(segs)
        for i in 0..<segs {
            let c: UIColor = (i % 2 == 0) ? UIColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 1)
                                           : UIColor(white: 0.12, alpha: 1)
            box(segW, 0.4, 0.18, color: c, Float(-1.0 + Double(i) * Double(segW) + Double(segW) / 2), 1.9)
        }
        // hanging warning sign
        box(0.7, 0.42, 0.08, color: UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1), 0, 1.35, 0.1)
    }

    /// Subway car — full block (3.2 tall, 6 long), must change lanes.
    private func buildTrain() {
        let bodyW: CGFloat = 2.0
        let bodyH: CGFloat = 3.2
        let bodyD: CGFloat = 6.0
        let teal = UIColor(red: 0.16, green: 0.35, blue: 0.45, alpha: 1)
        // car body
        let body = SCNNode(geometry: SCNBox(width: bodyW, height: bodyH, length: bodyD, chamferRadius: 0.12))
        body.geometry?.materials = [mat(teal)]
        body.position = SCNVector3(0, Float(bodyH / 2), 0)
        addChildNode(body)
        // roof
        box(bodyW, 0.3, bodyD, color: UIColor(white: 0.18, alpha: 1), 0, Float(bodyH) + 0.15)
        // windshield (front face, +z toward the player)
        box(1.4, 0.8, 0.06, color: UIColor(red: 0.65, green: 0.85, blue: 0.95, alpha: 1), 0, 2.3, Float(bodyD / 2) + 0.01)
        // headlights
        let lampC = UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 1)
        sphere(0.14, color: lampC, -0.55, 1.5, Float(bodyD / 2) + 0.05)
        sphere(0.14, color: lampC, 0.55, 1.5, Float(bodyD / 2) + 0.05)
        // bumper stripe
        box(bodyW - 0.12, 0.22, 0.06, color: UIColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1), 0, 0.6, Float(bodyD / 2) + 0.01)
        // side window strip
        box(0.06, 0.6, bodyD - 0.6, color: UIColor(red: 0.1, green: 0.16, blue: 0.2, alpha: 1), Float(bodyW / 2) + 0.01, 2.4)
        box(0.06, 0.6, bodyD - 0.6, color: UIColor(red: 0.1, green: 0.16, blue: 0.2, alpha: 1), -Float(bodyW / 2) - 0.01, 2.4)
    }
}
