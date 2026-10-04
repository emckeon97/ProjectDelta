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

    private let jumpDuration = 0.88
    private let rollDuration = 0.75
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
        body.eulerAngles.z = 0  // the tumble ends on a multiple of 360°, so the snap is invisible
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

        // lane-change lean: tilt into the glide direction (eases back after a roll)
        let lateral = targetX - position.x
        let targetLean = max(-0.3, min(0.3, lateral * 0.15))
        if state != .rolling {
            body.eulerAngles.z += (targetLean - body.eulerAngles.z) * min(1, Float(dt) * 10)
        }

        // jump arc: y = 3.5 * sin(pi * t)
        if jumpT < 1.0 {
            jumpT = min(1.0, jumpT + dt / jumpDuration)
            if jumpT >= 1.0 {
                playerY = 0
                state = .running
                landT = 0.0
            } else {
                playerY = 3.5 * Float(sin(.pi * jumpT))
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

        // --- cartoon squash & stretch (mirrors the Android port) ---
        if state == .rolling {
            // tumble: two full spins across the roll, slight tuck mid-roll
            let rt = Float(rollT)
            let tuck = Float(sin(.pi * Double(rt)))
            body.eulerAngles.z = rt * Float(4 * .pi)
            body.scale = SCNVector3(1 + 0.06 * tuck, 0.55 - 0.05 * tuck, 1)
        } else {
            var sx: Float = 1
            var sy: Float = 1
            if jumpT < 1.0 {
                // jump stretch peaks mid-air
                let s = Float(sin(.pi * jumpT))
                sx = 1 - 0.16 * s
                sy = 1 + 0.28 * s
            } else if landT < 0.22 {
                // landing squash, then recover
                landT += dt
                let k = 1 - Float(landT / 0.22)
                sx = 1 + 0.14 * k
                sy = 1 - 0.22 * k
            }
            // slide stretch while changing lanes
            let slideK = min(1, abs(lateral) / 2.2)
            sx += 0.16 * slideK
            sy -= 0.06 * slideK
            body.scale = SCNVector3(sx, sy, 1)
        }

        // subtle running bob
        if state == .running {
            runPhase += dt * 14
            body.position.y = Float(sin(runPhase)) * 0.05
        }
    }
}
