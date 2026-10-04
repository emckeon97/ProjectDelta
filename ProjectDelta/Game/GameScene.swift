import SceneKit

/// Project Delta gameplay in 3D: a 3-lane endless runner.
/// Player runs at z = 0 facing -z; the world streams toward +z.
final class GameScene: SCNScene, SCNSceneRendererDelegate {

    // MARK: - Public interface

    /// Called on crash: (score, coinsCollected).
    var onGameOver: ((Int, Int) -> Void)?
    /// Called each time a coin is collected (HUD tick).
    var onCoin: (() -> Void)?

    /// Set by GameView to freeze the simulation (pause overlay / backgrounding).
    var gamePaused: Bool = false

    static let laneX: [Float] = [-2.2, 0, 2.2]

    func configure(characterID: String) {
        self.characterID = characterID
        buildPlayer()
    }

    func moveLeft() { guard phase == .running else { return }; player?.moveLeft() }
    func moveRight() { guard phase == .running else { return }; player?.moveRight() }
    func jump() { guard phase == .running else { return }; player?.jump() }
    func roll() { guard phase == .running else { return }; player?.roll() }

    // MARK: - Tuning

    private enum Phase { case ready, running, over }

    private let spawnZ: Float = -70
    private let despawnZ: Float = 12
    private let baseSpeed: Float = 8
    private let maxSpeed: Float = 22
    private let speedRamp: Float = 0.35     // u/s gained per second
    private let powerDuration: TimeInterval = 8
    private let magnetRadius: Float = 6
    private let magnetPull: Float = 14
    private let scrollSpan: Float = 164     // dash/tie wrap distance

    // MARK: - State

    private var phase: Phase = .ready
    private var characterID = "willie"

    private var player: Player?
    private var obstacles: [Obstacle] = []
    private var coins: [Coin] = []
    private var powerUps: [PowerUp] = []
    private var scrollers: [SCNNode] = []

    private var lastUpdate: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var scrollSpeed: Float = 8
    private var score: Double = 0
    private var coinCount = 0

    private var magnetTime: TimeInterval = 0
    private var multiplierTime: TimeInterval = 0

    private var rowTimer: TimeInterval = 1.2
    private var coinTimer: TimeInterval = 0.5
    private var powerTimer: TimeInterval = 14

    // MARK: - Setup

    override init() {
        super.init()
        buildWorld()
        buildPlayer()
        phase = .running
    }

    required init?(coder: NSCoder) { nil }

    private func mat(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.roughness.contents = 0.7
        return m
    }

    private func buildWorld() {
        background.contents = UIColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1)

        let fog = SCNFog()
        fog.startDistance = 35
        fog.endDistance = 95
        fog.color = UIColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1)
        self.fog = fog

        // Camera
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 60
        cam.position = SCNVector3(0, 5.4, 8.0)
        let lookTarget = SCNNode()
        lookTarget.position = SCNVector3(0, 1.2, -8)
        addChildNode(lookTarget)
        cam.constraints = [SCNLookAtConstraint(target: lookTarget)]
        addChildNode(cam)

        // Lighting: ambient + one directional from above-front
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 700
        ambient.light?.color = UIColor(white: 0.9, alpha: 1)
        addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1100
        sun.position = SCNVector3(4, 10, 6)
        sun.constraints = [SCNLookAtConstraint(target: lookTarget)]
        addChildNode(sun)

        // Ground
        let ground = SCNNode(geometry: SCNPlane(width: 34, height: 180))
        ground.geometry?.materials = [mat(UIColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 1))]
        ground.eulerAngles.x = -Float.pi / 2
        ground.position = SCNVector3(0, 0, -60)
        addChildNode(ground)

        // Lane strips
        for x in GameScene.laneX {
            let strip = SCNNode(geometry: SCNBox(width: 1.9, height: 0.04, length: 170, chamferRadius: 0))
            strip.geometry?.materials = [mat(UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1))]
            strip.position = SCNVector3(x, 0.02, -60)
            addChildNode(strip)
        }

        // Side rails (static)
        for x in [-3.5, 3.5] as [Float] {
            let rail = SCNNode(geometry: SCNBox(width: 0.25, height: 0.5, length: 170, chamferRadius: 0.03))
            rail.geometry?.materials = [mat(UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1))]
            rail.position = SCNVector3(x, 0.25, -60)
            addChildNode(rail)
        }

        // Scrolling dashed dividers
        let dashMat = mat(UIColor(white: 0.35, alpha: 1))
        var z: Float = -140
        while z < 24 {
            for x in [-1.1, 1.1] as [Float] {
                let dash = SCNNode(geometry: SCNBox(width: 0.14, height: 0.05, length: 1.4, chamferRadius: 0.02))
                dash.geometry?.materials = [dashMat]
                dash.position = SCNVector3(x, 0.05, z)
                addChildNode(dash)
                scrollers.append(dash)
            }
            z += 4
        }

        // Scrolling cross ties
        let tieMat = mat(UIColor(white: 0.16, alpha: 1))
        z = -140
        while z < 24 {
            let tie = SCNNode(geometry: SCNBox(width: 7.2, height: 0.03, length: 0.5, chamferRadius: 0))
            tie.geometry?.materials = [tieMat]
            tie.position = SCNVector3(0, 0.015, z)
            addChildNode(tie)
            scrollers.append(tie)
            z += 8
        }

        // Distant side blocks for depth
        let blockMat = mat(UIColor(red: 0.09, green: 0.10, blue: 0.15, alpha: 1))
        for i in 0..<12 {
            let h = Float.random(in: 3...9)
            let w = Float.random(in: 2...4)
            let side: Float = (i % 2 == 0) ? -1 : 1
            let block = SCNNode(geometry: SCNBox(width: w, height: h, length: w, chamferRadius: 0.1))
            block.geometry?.materials = [blockMat]
            block.position = SCNVector3(side * Float.random(in: 8...14), h / 2, Float.random(in: -120...10))
            addChildNode(block)
        }
    }

    private func buildPlayer() {
        player?.removeFromParentNode()
        let p = Player(characterID: characterID)
        p.position = SCNVector3(0, 0, 0)
        addChildNode(p)
        player = p
    }

    // MARK: - Update loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !gamePaused, phase == .running, let player else { return }

        let dt: TimeInterval
        if lastUpdate == 0 {
            dt = 0
        } else {
            dt = min(time - lastUpdate, 1.0 / 30.0)
        }
        lastUpdate = time
        guard dt > 0 else { return }

        elapsed += dt
        scrollSpeed = min(maxSpeed, baseSpeed + speedRamp * Float(elapsed))

        // score = distance in meters, doubled while multiplier is live
        let mult: Double = multiplierTime > 0 ? 2 : 1
        score += Double(scrollSpeed * Float(dt)) * mult

        if magnetTime > 0 { magnetTime -= dt }
        if multiplierTime > 0 { multiplierTime -= dt }

        player.update(dt)
        scrollWorld(dt: dt)
        for coin in coins { coin.spin(dt) }
        for pu in powerUps { pu.spin(dt) }
        handlePickups(player: player, dt: dt)
        checkCollisions(player: player)
        cleanup()
        tickSpawners(dt: dt)
    }

    private func scrollWorld(dt: TimeInterval) {
        let dz = scrollSpeed * Float(dt)
        for ob in obstacles { ob.position.z += dz }
        for c in coins { c.position.z += dz }
        for p in powerUps { p.position.z += dz }
        for s in scrollers {
            s.position.z += dz
            if s.position.z > 24 { s.position.z -= scrollSpan }
        }
    }

    // MARK: - Pickups

    private func handlePickups(player: Player, dt: TimeInterval) {
        let center = SCNVector3(player.position.x, 0.9 + player.playerY, 0)

        var toCollect: [Coin] = []
        var toActivate: [PowerUp] = []

        for coin in coins {
            let d = distance3D(coin.position, center)
            if magnetTime > 0 && d < magnetRadius && d > 0.05 {
                let dir = normalize3D(center - coin.position)
                coin.position = coin.position + dir * (magnetPull * Float(dt))
            }
            if distance3D(coin.position, center) < 1.05 {
                toCollect.append(coin)
            }
        }

        for pu in powerUps {
            if distance3D(pu.position, center) < 1.15 {
                toActivate.append(pu)
            }
        }

        for coin in toCollect { collect(coin: coin) }
        for pu in toActivate { activate(powerUp: pu) }
    }

    private func distance3D(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        let d = a - b
        return sqrt(d.x * d.x + d.y * d.y + d.z * d.z)
    }

    private func normalize3D(_ v: SCNVector3) -> SCNVector3 {
        let len = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
        guard len > 0.0001 else { return SCNVector3Zero }
        return v / len
    }

    private func collect(coin: Coin) {
        guard let i = coins.firstIndex(where: { $0 === coin }) else { return }
        coins.remove(at: i)
        coin.removeFromParentNode()
        coinCount += 1
        onCoin?()
    }

    private func activate(powerUp: PowerUp) {
        guard let i = powerUps.firstIndex(where: { $0 === powerUp }) else { return }
        powerUps.remove(at: i)
        powerUp.removeFromParentNode()
        switch powerUp.kind {
        case .magnet: magnetTime = powerDuration
        case .multiplier: multiplierTime = powerDuration
        }
    }

    // MARK: - Collisions

    private func checkCollisions(player: Player) {
        for ob in obstacles {
            guard abs(ob.position.z) < 0.9 else { continue }
            guard abs(player.position.x - GameScene.laneX[ob.laneIndex]) < 1.0 else { continue }
            switch ob.kind {
            case .barrier:
                // low hurdle: only deadly if the player's feet are still low
                if player.playerY > 0.9 { continue }
                return gameOver()
            case .overhead:
                // high bar: rolling ducks under it
                if player.isRolling { continue }
                return gameOver()
            case .train:
                return gameOver()
            }
        }
    }

    private func gameOver() {
        guard phase == .running else { return }
        phase = .over
        onGameOver?(Int(score), coinCount)
    }

    // MARK: - Spawning

    private func tickSpawners(dt: TimeInterval) {
        rowTimer -= dt
        if rowTimer <= 0 {
            spawnObstacleRow()
            // keep a minimum physical gap between rows so lane changes stay possible
            rowTimer = max(0.55, 9.0 / Double(scrollSpeed))
        }

        coinTimer -= dt
        if coinTimer <= 0 {
            spawnCoinRun()
            coinTimer = Double.random(in: 0.9...1.6)
        }

        powerTimer -= dt
        if powerTimer <= 0 {
            spawnPowerUp()
            powerTimer = Double.random(in: 16...24)
        }
    }

    /// One row of obstacles across the lanes. Never blocks all three lanes with
    /// trains, so there is always a survivable path.
    private func spawnObstacleRow() {
        var kinds: [ObstacleKind?] = [nil, nil, nil]
        let blockedCount = Int.random(in: 1...2)
        let lanes = [0, 1, 2].shuffled()
        for i in 0..<blockedCount {
            let r = Double.random(in: 0...1)
            let kind: ObstacleKind
            if r < 0.40 { kind = .barrier }
            else if r < 0.70 { kind = .overhead }
            else { kind = .train }
            kinds[lanes[i]] = kind
        }
        for lane in 0..<3 {
            guard let kind = kinds[lane] else { continue }
            let ob = Obstacle(kind: kind, laneIndex: lane)
            ob.position = SCNVector3(GameScene.laneX[lane], 0, spawnZ)
            addChildNode(ob)
            obstacles.append(ob)
        }
    }

    /// A run of coins: straight line or zig-zag across lanes.
    private func spawnCoinRun() {
        let zigzag = Double.random(in: 0...1) < 0.3
        let count = Int.random(in: 6...9)
        var lane = Int.random(in: 0...2)
        let dir = Bool.random() ? 1 : -1
        for i in 0..<count {
            if zigzag, i > 0, i % 3 == 0 {
                lane = min(2, max(0, lane + dir))
            }
            let coin = Coin()
            coin.position = SCNVector3(GameScene.laneX[lane], 0.9, spawnZ - Float(i) * 1.1)
            addChildNode(coin)
            coins.append(coin)
        }
    }

    private func spawnPowerUp() {
        let kind: PowerUpKind = Bool.random() ? .magnet : .multiplier
        let pu = PowerUp(kind: kind)
        pu.position = SCNVector3(GameScene.laneX[Int.random(in: 0...2)], 1.1, spawnZ - 2)
        addChildNode(pu)
        powerUps.append(pu)
    }

    // MARK: - Cleanup

    private func cleanup() {
        obstacles.removeAll { ob in
            if ob.position.z > despawnZ {
                ob.removeFromParentNode()
                return true
            }
            return false
        }
        coins.removeAll { c in
            if c.position.z > despawnZ {
                c.removeFromParentNode()
                return true
            }
            return false
        }
        powerUps.removeAll { p in
            if p.position.z > despawnZ {
                p.removeFromParentNode()
                return true
            }
            return false
        }
    }
}

// MARK: - SCNVector3 helpers

private func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
}

private func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

private func * (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
    SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
}

private func / (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
    SCNVector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
}
