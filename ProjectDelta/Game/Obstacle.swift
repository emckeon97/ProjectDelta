import SceneKit

// MARK: - Obstacles (steamboat-river themed)

enum ObstacleKind {
    case barrier    // rowboat — jump over it
    case overhead   // footbridge — roll under it
    case train      // paddle-wheeler steamboat — dodge!
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

    @discardableResult private func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, color: UIColor, _ x: Float, _ y: Float, _ z: Float = 0) -> SCNNode {
        let n = SCNNode(geometry: SCNBox(width: w, height: h, length: d, chamferRadius: 0.02))
        n.geometry?.materials = [mat(color)]
        n.position = SCNVector3(x, y, z)
        addChildNode(n)
        return n
    }

    @discardableResult private func sphere(_ r: CGFloat, color: UIColor, _ x: Float, _ y: Float, _ z: Float) -> SCNNode {
        let n = SCNNode(geometry: SCNSphere(radius: r))
        n.geometry?.materials = [mat(color)]
        n.position = SCNVector3(x, y, z)
        addChildNode(n)
        return n
    }

    @discardableResult private func cyl(_ r: CGFloat, _ h: CGFloat, color: UIColor, _ x: Float, _ y: Float, _ z: Float = 0) -> SCNNode {
        let n = SCNNode(geometry: SCNCylinder(radius: r, height: h))
        n.geometry?.materials = [mat(color)]
        n.position = SCNVector3(x, y, z)
        addChildNode(n)
        return n
    }

    @discardableResult private func torus(_ ring: CGFloat, _ pipe: CGFloat, color: UIColor, _ x: Float, _ y: Float, _ z: Float = 0) -> SCNNode {
        let n = SCNNode(geometry: SCNTorus(ringRadius: ring, pipeRadius: pipe))
        n.geometry?.materials = [mat(color)]
        n.position = SCNVector3(x, y, z)
        addChildNode(n)
        return n
    }

    private func build() {
        switch kind {
        case .barrier: buildRowboat()
        case .overhead: buildFootbridge()
        case .train: buildSteamboat()
        }
    }

    /// Rowboat drifting across the pier — jump it (top at y≈1.0).
    private func buildRowboat() {
        let wood = UIColor(red: 0.36, green: 0.31, blue: 0.27, alpha: 1)
        let woodDark = UIColor(red: 0.24, green: 0.20, blue: 0.17, alpha: 1)
        // hull: long axis across the lane
        box(2.6, 0.7, 1.2, color: wood, 0, 0.5)
        // tapered bow / stern
        let bowL = box(0.7, 0.6, 1.0, color: wood, -1.45, 0.5)
        bowL.eulerAngles.z = Float.pi / 5
        let bowR = box(0.7, 0.6, 1.0, color: wood, 1.45, 0.5)
        bowR.eulerAngles.z = -Float.pi / 5
        // gunwale rim
        box(2.75, 0.12, 0.10, color: woodDark, 0, 0.90, 0.60)
        box(2.75, 0.12, 0.10, color: woodDark, 0, 0.90, -0.60)
        box(0.10, 0.12, 1.30, color: woodDark, -1.32, 0.90)
        box(0.10, 0.12, 1.30, color: woodDark, 1.32, 0.90)
        // bench seats
        box(0.28, 0.08, 1.05, color: woodDark, -0.55, 0.72)
        box(0.28, 0.08, 1.05, color: woodDark, 0.55, 0.72)
        // oar resting across the boat
        let oar = cyl(0.035, 2.4, color: woodDark, 0.1, 0.99)
        oar.eulerAngles.z = Float.pi / 2 - 0.12
    }

    /// Low wooden footbridge — roll under it (beam spans y 1.7–2.1).
    private func buildFootbridge() {
        let wood = UIColor(red: 0.32, green: 0.28, blue: 0.24, alpha: 1)
        let woodDark = UIColor(red: 0.22, green: 0.19, blue: 0.16, alpha: 1)
        // support posts
        box(0.22, 2.6, 0.22, color: wood, -1.05, 1.3)
        box(0.22, 2.6, 0.22, color: wood, 1.05, 1.3)
        // deck beam (the part you duck under): y 1.72–2.08
        box(2.35, 0.36, 0.9, color: wood, 0, 1.9)
        // plank seams on the beam face
        for i in 0..<5 {
            let px = Float(-0.9 + Double(i) * 0.45)
            box(0.05, 0.36, 0.92, color: woodDark, px, 1.9)
        }
        // decorative arch above the deck
        for i in 0..<5 {
            let t = Float(i) / 4.0
            let ax = -1.05 + t * 2.1
            let ay: Float = 2.35 + sin(t * Float.pi) * 0.55
            let seg = box(0.5, 0.14, 0.5, color: woodDark, ax, ay)
            seg.eulerAngles.z = (0.5 - t) * 0.9
        }
        // hanging lantern — a warm glow in the monochrome world
        cyl(0.02, 0.3, color: woodDark, 0, 1.58)
        let lamp = sphere(0.13, color: UIColor(red: 1, green: 0.92, blue: 0.75, alpha: 1), 0, 1.38, 0)
        let lampMat = SCNMaterial()
        lampMat.diffuse.contents = UIColor(red: 1, green: 0.92, blue: 0.75, alpha: 1)
        lampMat.emission.contents = UIColor(red: 1, green: 0.88, blue: 0.68, alpha: 1)
        lamp.geometry?.materials = [lampMat]
    }

    /// Paddle-wheeler steamboat blocking the lane — dodge! (~3.2 tall, 6 long).
    private func buildSteamboat() {
        let hullC = UIColor(white: 0.10, alpha: 1)
        let cabinC = UIColor(white: 0.72, alpha: 1)
        let trimC = UIColor(white: 0.52, alpha: 1)
        let stackC = UIColor(white: 0.05, alpha: 1)
        // hull
        box(2.0, 1.0, 6.0, color: hullC, 0, 0.5)
        // tapered bow (front, +z toward the player)
        let bow = box(1.4, 0.9, 1.2, color: hullC, 0, 0.45, 3.3)
        bow.eulerAngles.x = -0.35
        // stacked cabins
        box(1.7, 0.9, 4.6, color: cabinC, 0, 1.45)
        box(1.4, 0.8, 3.4, color: cabinC, 0, 2.30)
        // roofs
        box(1.9, 0.12, 4.8, color: trimC, 0, 1.96)
        box(1.6, 0.12, 3.6, color: trimC, 0, 2.76)
        // lit cabin windows (warm dots in the monochrome world)
        let winMat = SCNMaterial()
        winMat.diffuse.contents = UIColor(red: 1, green: 0.88, blue: 0.66, alpha: 1)
        winMat.emission.contents = UIColor(red: 1, green: 0.88, blue: 0.66, alpha: 1)
        for i in 0..<4 {
            let wz = Float(-1.2 + Double(i) * 0.8)
            for side in [-0.86, 0.86] as [Float] {
                let win = SCNNode(geometry: SCNBox(width: 0.34, height: 0.34, length: 0.06, chamferRadius: 0))
                win.geometry?.materials = [winMat]
                win.eulerAngles.y = side > 0 ? Float.pi / 2 : -Float.pi / 2
                win.position = SCNVector3(side, 1.45, wz)
                addChildNode(win)
            }
        }
        // smokestacks with caps
        cyl(0.18, 1.3, color: stackC, -0.4, 3.00, -1.2)
        cyl(0.18, 1.3, color: stackC, 0.4, 3.00, -1.2)
        cyl(0.24, 0.15, color: stackC, -0.4, 3.68, -1.2)
        cyl(0.24, 0.15, color: stackC, 0.4, 3.68, -1.2)
        // static smoke puffs
        let smokeMat = SCNMaterial()
        smokeMat.diffuse.contents = UIColor(white: 0.7, alpha: 1)
        smokeMat.transparency.contents = 0.45
        for (sx, sy) in [(-0.4, 4.15), (0.4, 4.40), (0.0, 4.65)] as [(Float, Float)] {
            let puff = SCNNode(geometry: SCNSphere(radius: 0.35, segmentCount: 12))
            puff.geometry?.materials = [smokeMat]
            puff.position = SCNVector3(sx, sy, -1.2)
            addChildNode(puff)
        }
        // paddle wheel on the starboard side (the one red accent)
        let wheelC = UIColor(red: 0.62, green: 0.16, blue: 0.14, alpha: 1)
        let wheel = torus(0.75, 0.13, color: wheelC, 1.12, 0.95)
        wheel.eulerAngles.y = Float.pi / 2
        for i in 0..<4 {
            let spoke = box(0.08, 1.4, 0.08, color: wheelC, 1.12, 0.95)
            spoke.eulerAngles.x = Float(i) * Float.pi / 4
        }
        // wheel housing arch over it
        let housing = box(0.18, 0.5, 1.9, color: hullC, 1.05, 1.85)
        housing.eulerAngles.x = 0.0
    }
}
