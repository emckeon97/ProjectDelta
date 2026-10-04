import SceneKit

/// The runner avatar. Wraps the code-drawn 3D character art and owns
/// lane / jump / roll animation state. Node origin is at the feet.
final class Player: SCNNode {

    enum State {
        case running
        case jumping
        case rolling
    }

    private(set) var state: State = .running
    private(set) var laneIndex: Int = 1
    private(set) var playerY: Float = 0    // current jump height above ground
    var isRolling: Bool { state == .rolling }

    private let body: SCNNode
    private var targetX: Float = 0
    private var jumpT: Double = 1.0    // 0...1 jump progress; 1 = grounded
    private var rollT: Double = 1.0    // 0...1 roll progress; 1 = standing
    private var landT: Double = 1.0    // 0...0.22 land-squash progress; 1 = inactive
    private var runPhase: Double = 0

    private let jumpDuration = 0.55
    private let rollDuration = 0.6
    private let laneSpeed: Float = 12

    init(characterID: String) {
        body = CharacterRenderer.node(for: characterID)
        super.init()
        addChildNode(body)
    }

    required init?(coder: NSCoder) { nil }

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
            playerY = 0
            body.position.y = 0
        }
        guard state != .rolling else { return }
        state = .rolling
        rollT = 0
        body.scale.y = 0.55
    }

    private func endRoll() {
        rollT = 1.0
        body.scale.y = 1.0
    }

    // MARK: - Update

    func update(_ dt: TimeInterval) {
        // lane glide
        let dx = targetX - position.x
        let step = laneSpeed * Float(dt)
        if abs(dx) <= step {
            position.x = targetX
        } else {
            position.x += (dx > 0 ? step : -step)
        }

        // lane-change lean: tilt into the glide direction
        let lateral = targetX - position.x
        let targetLean = max(-0.3, min(0.3, lateral * 0.15))
        body.eulerAngles.z += (targetLean - body.eulerAngles.z) * min(1, Float(dt) * 10)

        // jump arc: y = 3.2 * sin(pi * t)
        if jumpT < 1.0 {
            jumpT = min(1.0, jumpT + dt / jumpDuration)
            if jumpT >= 1.0 {
                playerY = 0
                state = .running
                landT = 0.0
            } else {
                playerY = 3.2 * Float(sin(.pi * jumpT))
                // jump stretch: tall and thin mid-air
                let s = Float(sin(.pi * jumpT))
                body.scale = SCNVector3(1 - 0.07 * s, 1 + 0.10 * s, 1)
            }
            body.position.y = playerY
        }

        // roll timer
        if rollT < 1.0 {
            rollT = min(1.0, rollT + dt / rollDuration)
            if rollT >= 1.0 {
                endRoll()
                state = .running
            }
        }

        // land squash: brief wide-and-flat on touchdown (never while rolling)
        if state == .running && landT < 0.22 {
            landT += dt
            let k = 1 - Float(landT / 0.22)
            body.scale = SCNVector3(1 + 0.10 * k, 1 - 0.16 * k, 1)
        } else if state == .running && landT >= 0.22 && !isRolling {
            body.scale = SCNVector3(1, 1, 1)
        }

        // subtle running bob
        if state == .running {
            runPhase += dt * 14
            body.position.y = Float(sin(runPhase)) * 0.05
        }
    }
}
