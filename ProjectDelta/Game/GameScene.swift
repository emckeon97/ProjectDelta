import SpriteKit

/// Project Delta gameplay: a 3-lane endless runner.
/// World scrolls downward; the player dodges, jumps, and rolls past obstacles.
final class GameScene: SKScene {

    // MARK: - Public interface (per BUILD_SPEC)

    /// Called on crash: (score, coinsCollected).
    var onGameOver: ((Int, Int) -> Void)?
    /// Called each time a coin is collected (HUD tick).
    var onCoin: (() -> Void)?

    static let laneX: [CGFloat] = [-110, 0, 110]

    func configure(characterID: String) {
        self.characterID = characterID
        if isReady { buildPlayer() }
    }

    func moveLeft() { guard phase == .running else { return }; player?.moveLeft() }
    func moveRight() { guard phase == .running else { return }; player?.moveRight() }
    func jump() { guard phase == .running else { return }; player?.jump() }
    func roll() { guard phase == .running else { return }; player?.roll() }

    func setPausedGame(_ paused: Bool) {
        isPaused = paused
    }

    // MARK: - Tuning

    private enum Phase { case ready, running, over }

    private let playerRestY: CGFloat = -250
    private let spawnY: CGFloat = 500
    private let despawnY: CGFloat = -480
    private let baseSpeed: CGFloat = 420
    private let maxSpeed: CGFloat = 950
    private let speedRamp: CGFloat = 6        // pt/s gained per second
    private let powerDuration: TimeInterval = 8
    private let magnetRadius: CGFloat = 150
    private let magnetPull: CGFloat = 700

    // MARK: - State

    private var phase: Phase = .ready
    private var isReady = false
    private var characterID = "willie"

    private var player: Player?
    private var obstacles: [Obstacle] = []
    private var coins: [Coin] = []
    private var powerUps: [PowerUp] = []
    private var dashes: [SKShapeNode] = []

    private var lastUpdate: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var scrollSpeed: CGFloat = 420
    private var score: Double = 0
    private var coinCount = 0

    private var magnetTime: TimeInterval = 0
    private var multiplierTime: TimeInterval = 0

    private var rowTimer: TimeInterval = 1.2
    private var coinTimer: TimeInterval = 0.5
    private var powerTimer: TimeInterval = 14

    // MARK: - Setup

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 1)
        buildTrack()
        buildPlayer()
        isReady = true
        phase = .running
    }

    private func buildPlayer() {
        player?.removeFromParent()
        let p = Player(characterID: characterID)
        p.position = CGPoint(x: 0, y: playerRestY)
        p.targetX = 0
        addChild(p)
        player = p
    }

    /// Lane separators (scrolling dashes) + static side rails.
    private func buildTrack() {
        // side rails
        for x in [-172, 172] as [CGFloat] {
            let rail = SKShapeNode(rect: CGRect(x: x - 5, y: -450, width: 10, height: 900))
            rail.fillColor = SKColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1)
            rail.strokeColor = .clear
            rail.isAntialiased = true
            addChild(rail)
        }
        // scrolling dashes between lanes
        let dashH: CGFloat = 34
        let gap: CGFloat = 44
        let span: CGFloat = 940
        for x in [-55, 55] as [CGFloat] {
            var y: CGFloat = -470
            while y < 470 {
                let dash = SKShapeNode(rect: CGRect(x: x - 3, y: y, width: 6, height: dashH), cornerRadius: 3)
                dash.fillColor = SKColor(white: 0.35, alpha: 1)
                dash.strokeColor = .clear
                dash.isAntialiased = true
                dash.userData = NSMutableDictionary(dictionary: ["span": span])
                addChild(dash)
                dashes.append(dash)
                y += dashH + gap
            }
        }
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        guard phase == .running, let player else { return }

        let dt: TimeInterval
        if lastUpdate == 0 {
            dt = 0
        } else {
            dt = min(currentTime - lastUpdate, 1.0 / 30.0)
        }
        lastUpdate = currentTime
        guard dt > 0 else { return }

        elapsed += dt
        scrollSpeed = min(maxSpeed, baseSpeed + speedRamp * CGFloat(elapsed))

        // score from distance (1 m per 50 pt), doubled while multiplier is live
        let mult: Double = multiplierTime > 0 ? 2 : 1
        score += Double(scrollSpeed * CGFloat(dt) / 50) * mult

        if magnetTime > 0 { magnetTime -= dt }
        if multiplierTime > 0 { multiplierTime -= dt }

        player.update(dt)
        scrollWorld(dt: dt)
        handlePickups(player: player, dt: dt)
        checkCollisions(player: player)
        cleanup()
        tickSpawners(dt: dt)
    }

    private func scrollWorld(dt: TimeInterval) {
        let dy = scrollSpeed * CGFloat(dt)
        for ob in obstacles { ob.position.y -= dy }
        for c in coins { c.position.y -= dy }
        for p in powerUps { p.position.y -= dy }
        for d in dashes {
            d.position.y -= dy
            if d.position.y < -470 {
                let span = (d.userData?["span"] as? CGFloat) ?? 940
                d.position.y += span
            }
        }
    }

    // MARK: - Pickups

    private func handlePickups(player: Player, dt: TimeInterval) {
        let center = player.centerPoint

        var toCollect: [Coin] = []
        var toActivate: [PowerUp] = []

        for coin in coins {
            let d = hypot(coin.position.x - center.x, coin.position.y - center.y)
            if magnetTime > 0 && d < magnetRadius && d > 1 {
                // pull toward the player
                let dx = (center.x - coin.position.x) / d
                let dy = (center.y - coin.position.y) / d
                coin.position.x += dx * magnetPull * CGFloat(dt)
                coin.position.y += dy * magnetPull * CGFloat(dt)
            }
            if hypot(coin.position.x - center.x, coin.position.y - center.y) < 52 {
                toCollect.append(coin)
            }
        }

        for pu in powerUps {
            let d = hypot(pu.position.x - center.x, pu.position.y - center.y)
            if d < 58 {
                toActivate.append(pu)
            }
        }

        for coin in toCollect { collect(coin: coin) }
        for pu in toActivate { activate(powerUp: pu) }
    }

    private func collect(coin: Coin) {
        guard let i = coins.firstIndex(where: { $0 === coin }) else { return }
        coins.remove(at: i)
        coin.removeFromParent()
        coinCount += 1
        onCoin?()
    }

    private func activate(powerUp: PowerUp) {
        guard let i = powerUps.firstIndex(where: { $0 === powerUp }) else { return }
        powerUps.remove(at: i)
        powerUp.removeFromParent()
        switch powerUp.kind {
        case .magnet: magnetTime = powerDuration
        case .multiplier: multiplierTime = powerDuration
        }
    }

    // MARK: - Collisions

    private func checkCollisions(player: Player) {
        let pr = player.collisionRect
        for ob in obstacles {
            let r = ob.collisionRect
            guard pr.intersects(r) else { continue }
            switch ob.kind {
            case .barrier:
                // low hurdle: only deadly if the player's feet are still low
                if player.feetOffset > 46 { continue }
                return gameOver()
            case .overhead:
                // high bar: rolling ducks under it
                if player.state == .rolling { continue }
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
            rowTimer = max(0.55, 470 / scrollSpeed)
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
            ob.position = CGPoint(x: GameScene.laneX[lane], y: spawnY)
            addChild(ob)
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
            coin.position = CGPoint(x: GameScene.laneX[lane], y: spawnY + CGFloat(i) * 56)
            addChild(coin)
            coins.append(coin)
        }
    }

    private func spawnPowerUp() {
        let kind: PowerUpKind = Bool.random() ? .magnet : .multiplier
        let pu = PowerUp(kind: kind)
        pu.position = CGPoint(x: GameScene.laneX[Int.random(in: 0...2)], y: spawnY + 60)
        addChild(pu)
        powerUps.append(pu)
    }

    // MARK: - Cleanup

    private func cleanup() {
        obstacles.removeAll { ob in
            if ob.position.y < despawnY {
                ob.removeFromParent()
                return true
            }
            return false
        }
        coins.removeAll { c in
            if c.position.y < despawnY {
                c.removeFromParent()
                return true
            }
            return false
        }
        powerUps.removeAll { p in
            if p.position.y < despawnY {
                p.removeFromParent()
                return true
            }
            return false
        }
    }
}
