import SpriteKit

/// The runner avatar. Wraps the code-drawn character art and owns
/// lane / jump / roll animation state. Node origin is at the feet.
final class Player: SKNode {

    enum State {
        case running
        case jumping
        case rolling
    }

    private(set) var state: State = .running
    private(set) var laneIndex: Int = 1
    private(set) var feetOffset: CGFloat = 0   // current jump height above ground

    var targetX: CGFloat = 0

    private let body: SKNode
    private var jumpT: Double = 1.0    // 0...1 jump progress; 1 = grounded
    private var rollT: Double = 1.0    // 0...1 roll progress; 1 = standing
    private var runPhase: Double = 0

    private let jumpDuration = 0.55
    private let rollDuration = 0.6
    private let jumpPeak: CGFloat = 120
    private let laneSpeed: CGFloat = 1100

    init(characterID: String) {
        body = CharacterRenderer.node(for: characterID)
        super.init()
        addChild(body)
    }

    required init?(coder: NSCoder) { nil }

    /// Scene-space collision rectangle (accounts for jump height and roll squash).
    var collisionRect: CGRect {
        switch state {
        case .running:
            return CGRect(x: position.x - 30, y: position.y, width: 60, height: 112)
        case .jumping:
            return CGRect(x: position.x - 30, y: position.y + feetOffset, width: 60, height: 112)
        case .rolling:
            return CGRect(x: position.x - 32, y: position.y, width: 64, height: 48)
        }
    }

    /// Center of the character, used for pickup attraction / collection.
    var centerPoint: CGPoint {
        CGPoint(x: position.x, y: position.y + 50 + feetOffset)
    }

    // MARK: - Controls

    func moveLeft() {
        laneIndex = max(0, laneIndex - 1)
        targetX = GameScene.laneX[laneIndex]
    }

    func moveRight() {
        laneIndex = min(2, laneIndex + 1)
        targetX = GameScene.laneX[laneIndex]
    }

    func jump() {
        guard state != .jumping else { return }
        if state == .rolling { endRoll() }
        state = .jumping
        jumpT = 0
    }

    func roll() {
        if state == .jumping {
            // slam down out of the jump
            jumpT = 1.0
            feetOffset = 0
            body.position.y = 0
        }
        guard state != .rolling else { return }
        state = .rolling
        rollT = 0
        body.yScale = 0.5
    }

    private func endRoll() {
        rollT = 1.0
        body.yScale = 1.0
    }

    // MARK: - Update

    func update(_ dt: TimeInterval) {
        // lane glide
        let dx = targetX - position.x
        let step = laneSpeed * CGFloat(dt)
        if abs(dx) <= step {
            position.x = targetX
        } else {
            position.x += (dx > 0 ? step : -step)
        }

        // jump arc: h = 4 * peak * t * (1 - t)
        if jumpT < 1.0 {
            jumpT = min(1.0, jumpT + dt / jumpDuration)
            if jumpT >= 1.0 {
                feetOffset = 0
                state = .running
            } else {
                feetOffset = jumpPeak * 4 * CGFloat(jumpT) * CGFloat(1.0 - jumpT)
            }
            body.position.y = feetOffset
        }

        // roll timer
        if rollT < 1.0 {
            rollT = min(1.0, rollT + dt / rollDuration)
            if rollT >= 1.0 {
                endRoll()
                state = .running
            }
        }

        // subtle running bob
        if state == .running {
            runPhase += dt * 14
            body.position.y = sin(runPhase) * 3
        }
    }
}
