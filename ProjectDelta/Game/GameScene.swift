import SceneKit

/// Project Delta gameplay in 3D: a 3-lane endless runner.
/// Player runs at z = 0 facing -z; the world streams toward +z.
///
/// Setting: a moonlit river in a 1930s cartoon — the player sprints along a
/// wooden pier over dark water, jumping rowboats, ducking under footbridges,
/// and dodging paddle-wheeler steamboats.
final class GameScene: SCNScene, SCNSceneRendererDelegate {

    // MARK: - Public interface

    /// Called on crash: (score, coinsCollected).
    var onGameOver: ((Int, Int) -> Void)?
    /// Called each time a coin is collected (HUD tick).
    var onCoin: (() -> Void)?

    /// Set by GameView to freeze the simulation (pause overlay / backgrounding).
    var gamePaused: Bool = false

    static let laneX: [Float] = [-2.2, 0, 2.2]

    private func sphere(_ r: CGFloat, _ seg: Int) -> SCNSphere {
        let s = SCNSphere(radius: r)
        s.segmentCount = seg
        return s
    }

    func configure(characterID: String) {
        self.characterID = characterID
        reel = 1
        reelDidChange = true // show the REEL 1 title card as the run starts
        buildPlayer()
        buildCameos()
    }

    func moveLeft() { guard phase == .running else { return }; player?.moveLeft() }
    func moveRight() { guard phase == .running else { return }; player?.moveRight() }
    func jump() { guard phase == .running else { return }; player?.jump() }
    func roll() { guard phase == .running else { return }; player?.roll() }

    // MARK: - Tuning

    private enum Phase { case ready, running, over }

    private let spawnZ: Float = -70
    private let despawnZ: Float = 12
    private let baseSpeed: Float = 10
    private let maxSpeed: Float = 26
    private let speedRamp: Float = 0.5      // u/s gained per second
    private let powerDuration: TimeInterval = 8
    private let magnetRadius: Float = 6
    private let magnetPull: Float = 14
    private let scrollSpan: Float = 164     // scroller wrap distance

    static let reelLength: Float = 500      // meters per silent-film reel (level)

    /**
     * The 1932 premiere story, told in silent-film title cards.
     * Our star is late for the biggest cartoon premiere of the year at the
     * Grand Picture Palace — every 500 meters is another reel of the race
     * down the old pier.
     */
    static func reelTitle(_ reel: Int) -> String {
        switch reel {
        case 1: return "DOWN AT THE LANDING"
        case 2: return "THE BUSY HARBOR"
        case 3: return "FOG ON THE RIVER"
        case 4: return "THE OLD FOOTBRIDGES"
        case 5: return "PREMIERE NIGHT"
        default: return "THE SHOW GOES ON"
        }
    }

    static func reelBlurb(_ reel: Int) -> String {
        switch reel {
        case 1:
            return "The year is 1932. The Grand Picture Palace premieres its biggest " +
                "cartoon tonight — and our star is running late! Sprint down the old pier!"
        case 2:
            return "Rowboats crowd the landing — the whole river is headed to the premiere. " +
                "Leap 'em and keep moving!"
        case 3:
            return "Fog rolls in thick as theater curtains. The paddle-wheelers can't see you… " +
                "and you can't see them!"
        case 4:
            return "Duck, star! The crew left every last footbridge down. The show must go on!"
        case 5:
            return "There it is — the marquee lights of the Grand Picture Palace! " +
                "One last sprint down the pier and you're a star!"
        default:
            return "The crowd roars for an encore! How long can you keep running?"
        }
    }

    // MARK: - State

    private var phase: Phase = .ready
    private var characterID = "popeye"

    private var player: Player?
    private var cameos: [SCNNode] = []
    private var obstacles: [Obstacle] = []
    private var coins: [Coin] = []
    private var powerUps: [PowerUp] = []
    private var scrollers: [SCNNode] = []

    /// Far-off riverboat silhouette; drifts slowly for ambient life.
    private var riverboat: SCNNode?
    private var riverboatBaseX: Float = 16

    private var lastUpdate: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var scrollSpeed: Float = 10
    private var score: Double = 0
    private var coinCount = 0

    /// Silent-film reel (level): 1 per reelLength meters, with a title card.
    private(set) var reel: Int = 1
    /// Set when the reel increments (or a run starts); the UI shows the
    /// title card, then resets this to false.
    var reelDidChange = false

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

    // MARK: - World: moonlit steamboat river

    private func buildWorld() {
        // Near-black navy sky, like an old cartoon reel at night.
        let skyColor = UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1)
        background.contents = skyColor

        fogStartDistance = 35
        fogEndDistance = 95
        fogColor = skyColor

        // Camera (unchanged)
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 60
        cam.position = SCNVector3(0, 5.4, 8.0)
        let lookTarget = SCNNode()
        lookTarget.position = SCNVector3(0, 1.2, -8)
        rootNode.addChildNode(lookTarget)
        cam.constraints = [SCNLookAtConstraint(target: lookTarget)]
        rootNode.addChildNode(cam)

        // Moonlight: cool ambient + one directional "moon" light
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 700
        ambient.light?.color = UIColor(red: 0.72, green: 0.80, blue: 0.95, alpha: 1)
        rootNode.addChildNode(ambient)

        let moonLight = SCNNode()
        moonLight.light = SCNLight()
        moonLight.light?.type = .directional
        moonLight.light?.intensity = 1100
        moonLight.light?.color = UIColor(red: 0.85, green: 0.90, blue: 1.0, alpha: 1)
        moonLight.position = SCNVector3(-5, 12, 2)
        moonLight.constraints = [SCNLookAtConstraint(target: lookTarget)]
        rootNode.addChildNode(moonLight)

        // The moon: bright emissive disc + soft halo
        let moonMat = SCNMaterial()
        moonMat.diffuse.contents = UIColor(white: 0.95, alpha: 1)
        moonMat.emission.contents = UIColor(white: 0.9, alpha: 1)
        let moon = SCNNode(geometry: sphere(5, 32))
        moon.geometry?.materials = [moonMat]
        moon.position = SCNVector3(-24, 22, -70)
        rootNode.addChildNode(moon)

        let haloMat = SCNMaterial()
        haloMat.diffuse.contents = UIColor(white: 1, alpha: 1)
        haloMat.emission.contents = UIColor(white: 0.55, alpha: 1)
        haloMat.transparency = 0.14
        let halo = SCNNode(geometry: sphere(8.5, 24))
        halo.geometry?.materials = [haloMat]
        halo.position = moon.position
        rootNode.addChildNode(halo)

        // Stars
        let starMat = SCNMaterial()
        starMat.diffuse.contents = UIColor(white: 1, alpha: 1)
        starMat.emission.contents = UIColor(white: 1, alpha: 1)
        for _ in 0..<44 {
            let star = SCNNode(geometry: sphere(CGFloat.random(in: 0.10...0.26), 6))
            star.geometry?.materials = [starMat]
            star.position = SCNVector3(Float.random(in: -90 ... 90),
                                       Float.random(in: 13...46),
                                       Float.random(in: -85 ... -50))
            rootNode.addChildNode(star)
        }

        // Water: one huge dark plane under everything
        let water = SCNNode(geometry: SCNPlane(width: 240, height: 260))
        water.geometry?.materials = [mat(UIColor(red: 0.03, green: 0.045, blue: 0.085, alpha: 1))]
        water.eulerAngles.x = -Float.pi / 2
        water.position = SCNVector3(0, -0.6, -60)
        rootNode.addChildNode(water)

        // Scrolling moonlit wave dashes on the water (2 rows per side)
        let waveMat = mat(UIColor(white: 0.50, alpha: 1))
        var z: Float = -140
        while z < 24 {
            for x in [-11.0, -7.0, 7.0, 11.0] as [Float] {
                let wave = SCNNode(geometry: SCNBox(width: 1.7, height: 0.03, length: 0.12, chamferRadius: 0.01))
                wave.geometry?.materials = [waveMat]
                wave.position = SCNVector3(x + Float.random(in: -0.7 ... 0.7), -0.55, z)
                rootNode.addChildNode(wave)
                scrollers.append(wave)
            }
            z += 4
        }

        // Wooden pier: dark base + scrolling individual planks with gaps
        let deckBase = SCNNode(geometry: SCNBox(width: 9.4, height: 0.3, length: 176, chamferRadius: 0))
        deckBase.geometry?.materials = [mat(UIColor(red: 0.20, green: 0.17, blue: 0.145, alpha: 1))]
        deckBase.position = SCNVector3(0, -0.20, -60)
        rootNode.addChildNode(deckBase)

        let plankMat = mat(UIColor(red: 0.30, green: 0.26, blue: 0.22, alpha: 1))
        z = -140
        while z < 24 {
            let plank = SCNNode(geometry: SCNBox(width: 9.4, height: 0.06, length: 1.7, chamferRadius: 0.01))
            plank.geometry?.materials = [plankMat]
            plank.position = SCNVector3(0, -0.03, z)
            rootNode.addChildNode(plank)
            scrollers.append(plank)
            z += 2
        }

        // Subtle lighter lane strips (weathered boards, no neon — film look)
        for x in GameScene.laneX {
            let strip = SCNNode(geometry: SCNBox(width: 1.9, height: 0.02, length: 176, chamferRadius: 0))
            strip.geometry?.materials = [mat(UIColor(red: 0.36, green: 0.32, blue: 0.28, alpha: 1))]
            strip.position = SCNVector3(x, 0.012, -60)
            rootNode.addChildNode(strip)
        }

        // Pier posts + rope rails. Each fence unit (post + rope to the next
        // post) scrolls and wraps on its own: 40 units x 4.1 = 164, seamless.
        let postMat = mat(UIColor(red: 0.24, green: 0.20, blue: 0.17, alpha: 1))
        let ropeMat = mat(UIColor(white: 0.55, alpha: 1))
        let fenceSpacing: Float = 4.1
        var fz: Float = -140
        while fz < 24 {
            for side in [-4.9, 4.9] as [Float] {
                let unit = SCNNode()
                let post = SCNNode(geometry: SCNCylinder(radius: 0.14, height: 1.3))
                post.geometry?.materials = [postMat]
                post.position = SCNVector3(0, 0.65, 0)
                unit.addChildNode(post)
                let cap = SCNNode(geometry: sphere(0.18, 12))
                cap.geometry?.materials = [postMat]
                cap.position = SCNVector3(0, 1.32, 0)
                unit.addChildNode(cap)
                let rope = SCNNode(geometry: SCNCylinder(radius: 0.045, height: CGFloat(fenceSpacing)))
                rope.geometry?.materials = [ropeMat]
                rope.eulerAngles.x = Float.pi / 2
                rope.position = SCNVector3(0, 1.02, -fenceSpacing / 2)
                unit.addChildNode(rope)
                unit.position = SCNVector3(side, 0, fz)
                rootNode.addChildNode(unit)
                scrollers.append(unit)
            }
            fz += fenceSpacing
        }

        // Distant hill silhouettes
        let hillMat = mat(UIColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1))
        for (hx, hr) in [(-42, 20), (-16, 14), (10, 17), (38, 22), (62, 15)] as [(Float, CGFloat)] {
            let hill = SCNNode(geometry: sphere(hr, 20))
            hill.geometry?.materials = [hillMat]
            hill.scale = SCNVector3(1.5, 0.42, 0.8)
            hill.position = SCNVector3(hx, -1.5, -88)
            rootNode.addChildNode(hill)
        }

        // Far-off riverboat silhouette with lit windows, drifting slowly
        let boat = SCNNode()
        let hullB = SCNNode(geometry: SCNBox(width: 15, height: 2.6, length: 4.2, chamferRadius: 0.2))
        hullB.geometry?.materials = [mat(UIColor(white: 0.06, alpha: 1))]
        hullB.position = SCNVector3(0, 1.0, 0)
        boat.addChildNode(hullB)
        let cabinB = SCNNode(geometry: SCNBox(width: 9.5, height: 2.1, length: 3.6, chamferRadius: 0.1))
        cabinB.geometry?.materials = [mat(UIColor(white: 0.10, alpha: 1))]
        cabinB.position = SCNVector3(0, 3.3, 0)
        boat.addChildNode(cabinB)
        let stackB = SCNNode(geometry: SCNCylinder(radius: 0.5, height: 2.6))
        stackB.geometry?.materials = [mat(UIColor(white: 0.05, alpha: 1))]
        stackB.position = SCNVector3(-2.5, 5.2, 0)
        boat.addChildNode(stackB)
        let winMat = SCNMaterial()
        winMat.diffuse.contents = UIColor(red: 1, green: 0.88, blue: 0.66, alpha: 1)
        winMat.emission.contents = UIColor(red: 1, green: 0.88, blue: 0.66, alpha: 1)
        for wx in stride(from: -3.4, through: 3.4, by: 1.7) {
            let win = SCNNode(geometry: SCNBox(width: 0.7, height: 0.7, length: 0.1, chamferRadius: 0))
            win.geometry?.materials = [winMat]
            win.position = SCNVector3(Float(wx), 3.3, 1.85)
            boat.addChildNode(win)
        }
        boat.position = SCNVector3(riverboatBaseX, -0.5, -80)
        rootNode.addChildNode(boat)
        riverboat = boat
    }

    private func buildPlayer() {
        player?.removeFromParentNode()
        let p = Player(characterID: characterID)
        p.position = SCNVector3(0, 0, 0)
        rootNode.addChildNode(p)
        player = p
    }

    /// Background cameos: 3 random roster characters (never the player) placed
    /// as decoration — two on the pier edges, one on the distant riverboat.
    /// Outside the lanes, so there's no collision confusion. Rebuilt on configure.
    private func buildCameos() {
        for c in cameos { c.removeFromParentNode() }
        cameos.removeAll()
        let others = GameCharacter.roster.map { $0.id }.filter { $0 != characterID }.shuffled()
        // (x, y, z, scale)
        let spots: [(Float, Float, Float, CGFloat)] = [
            (-4.6, 0, -18, 1.0),
            (4.6, 0, -18, 1.0),
            (riverboatBaseX, 1.2, -80, 2.5),
        ]
        for (i, spot) in spots.enumerated() where i < others.count {
            let n = CharacterRenderer.node(for: others[i])
            n.position = SCNVector3(spot.0, spot.1, spot.2)
            n.scale = SCNVector3(spot.3, spot.3, spot.3)
            let bob = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.12, z: 0, duration: 1.1),
                SCNAction.moveBy(x: 0, y: -0.12, z: 0, duration: 1.1),
            ])
            n.runAction(SCNAction.repeatForever(bob))
            rootNode.addChildNode(n)
            cameos.append(n)
        }
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

        // Ambient: the distant riverboat drifts slowly (dressing only).
        if let boat = riverboat {
            boat.position.x = riverboatBaseX + sin(Float(elapsed) * 0.08) * 5
        }

        // score = distance in meters, doubled while multiplier is live
        let mult: Double = multiplierTime > 0 ? 2 : 1
        score += Double(scrollSpeed * Float(dt)) * mult

        // silent-film reels: new title card every reelLength meters
        let newReel = Int(score / Double(GameScene.reelLength)) + 1
        if newReel != reel {
            reel = newReel
            reelDidChange = true
        }

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
            // keep breathing room between rows so jumps and lane changes stay possible
            rowTimer = max(0.7, 13.0 / Double(scrollSpeed))
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
        // Later reels crowd the pier a little more.
        let twoChance = min(0.75, 0.45 + 0.05 * Double(reel - 1))
        let blockedCount = Double.random(in: 0...1) < twoChance ? 2 : 1
        let lanes = [0, 1, 2].shuffled()
        for i in 0..<blockedCount {
            let r = Double.random(in: 0...1)
            let kind: ObstacleKind
            if r < 0.38 { kind = .barrier }
            else if r < 0.68 { kind = .overhead }
            else { kind = .train }
            kinds[lanes[i]] = kind
        }
        for lane in 0..<3 {
            guard let kind = kinds[lane] else { continue }
            let ob = Obstacle(kind: kind, laneIndex: lane)
            ob.position = SCNVector3(GameScene.laneX[lane], 0, spawnZ)
            rootNode.addChildNode(ob)
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
            rootNode.addChildNode(coin)
            coins.append(coin)
        }
    }

    private func spawnPowerUp() {
        let kind: PowerUpKind = Bool.random() ? .magnet : .multiplier
        let pu = PowerUp(kind: kind)
        pu.position = SCNVector3(GameScene.laneX[Int.random(in: 0...2)], 1.1, spawnZ - 2)
        rootNode.addChildNode(pu)
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
