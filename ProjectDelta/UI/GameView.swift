import SwiftUI
import SceneKit
import Combine

/// Optional hook: if GameScene exposes a live `currentScore`, the HUD polls it.
/// If the scene doesn't conform, the HUD score simply stays at its last value —
/// no compile dependency either way.
protocol ScoreProviding {
    var currentScore: Int { get }
}

/// Hosts the SceneKit runner. A fresh instance (and scene) is built per run.
final class GameViewController: UIViewController {
    var characterID: String = "willie"
    var onGameOver: ((Int, Int) -> Void)?
    var onCoin: (() -> Void)?

    private(set) var scene: GameScene?
    private var scnView: SCNView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = false
        scnView.isPlaying = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        view.addSubview(scnView)
        self.scnView = scnView

        let scene = GameScene()
        scene.configure(characterID: characterID)
        scene.onGameOver = { [weak self] score, coins in
            DispatchQueue.main.async {
                self?.onGameOver?(score, coins)
            }
        }
        scene.onCoin = { [weak self] in
            DispatchQueue.main.async {
                self?.onCoin?()
            }
        }
        self.scene = scene
        scnView.scene = scene
        scnView.delegate = scene
        addSwipeGestures(to: scnView)
    }

    private func addSwipeGestures(to scnView: SCNView) {
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for direction in directions {
            let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            recognizer.direction = direction
            scnView.addGestureRecognizer(recognizer)
        }
    }

    @objc private func handleSwipe(_ recognizer: UISwipeGestureRecognizer) {
        guard let scene = scene, !scene.gamePaused else { return }
        switch recognizer.direction {
        case .left:
            scene.moveLeft()
        case .right:
            scene.moveRight()
        case .up:
            scene.jump()
        case .down:
            scene.roll()
        default:
            break
        }
    }

    func setPaused(_ paused: Bool) {
        scene?.gamePaused = paused
    }

    deinit {
        scnView?.delegate = nil
        scnView?.scene = nil
    }
}

private struct GameViewRepresentable: UIViewControllerRepresentable {
    let characterID: String
    var onGameOver: (Int, Int) -> Void
    var onCoin: () -> Void
    var onReady: (GameViewController) -> Void

    func makeUIViewController(context: Context) -> GameViewController {
        let vc = GameViewController()
        vc.characterID = characterID
        vc.onGameOver = onGameOver
        vc.onCoin = onCoin
        // Defer: writing SwiftUI state during view update logs a warning.
        DispatchQueue.main.async { onReady(vc) }
        return vc
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}

/// The gameplay screen: SceneKit view + HUD overlay + pause handling.
struct GameView: View {
    @EnvironmentObject private var manager: CharacterManager
    var onGameOver: (Int, Int) -> Void
    var onQuit: (Int) -> Void

    @State private var controller: GameViewController?
    @State private var hudScore = 0
    @State private var hudCoins = 0
    @State private var isPaused = false
    @State private var finished = false
    @State private var reelCard: Int?

    private let scoreTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            GameViewRepresentable(
                characterID: manager.selectedID,
                onGameOver: { score, coins in
                    guard !finished else { return }
                    finished = true
                    controller?.setPaused(true)
                    onGameOver(score, coins)
                },
                onCoin: { hudCoins += 1 },
                onReady: { controller = $0 }
            )
            .ignoresSafeArea()

            // Old-film vignette over the 3D view (hit-testing off so swipes pass through)
            RadialGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.35)]),
                center: .center,
                startRadius: 120,
                endRadius: 480
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            HUDView(score: hudScore, coins: hudCoins, onPause: pauseGame)
                .opacity(isPaused ? 0 : 1)

            // Silent-film reel title card (hit-testing off so swipes pass through)
            if let reel = reelCard {
                ReelTitleCard(reel: reel)
                    .allowsHitTesting(false)
            }

            if isPaused && !finished {
                pauseOverlay
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onReceive(scoreTimer) { _ in
            guard !isPaused, !finished, let scene = controller?.scene else { return }
            if let provider = scene as? ScoreProviding {
                hudScore = provider.currentScore
            }
            if scene.reelDidChange {
                scene.reelDidChange = false
                reelCard = scene.reel
                Task {
                    try? await Task.sleep(nanoseconds: 2_600_000_000)
                    await MainActor.run { reelCard = nil }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            pauseGame()
        }
        .onDisappear {
            controller?.setPaused(true)
        }
    }

    private func pauseGame() {
        guard !finished, !isPaused else { return }
        isPaused = true
        controller?.setPaused(true)
    }

    private func resumeGame() {
        isPaused = false
        controller?.setPaused(false)
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Paused")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Button("Resume", action: resumeGame)
                    .buttonStyle(DeltaButtonStyle())
                Button("Quit to Menu") {
                    guard !finished else { return }
                    finished = true
                    onQuit(hudCoins)
                }
                .buttonStyle(DeltaSecondaryButtonStyle())
            }
            .padding(40)
        }
    }
}

/// Silent-film title card shown when a new reel (level) begins.
private struct ReelTitleCard: View {
    let reel: Int

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Text("REEL \(reel)")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .tracking(4)
                    .foregroundColor(DeltaTheme.gold)
                Text(GameScene.reelTitle(reel))
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundColor(DeltaTheme.cream)
                    .multilineTextAlignment(.center)
                Text(GameScene.reelBlurb(reel))
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(DeltaTheme.cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(DeltaTheme.gold, lineWidth: 2)
                    .padding(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(DeltaTheme.gold.opacity(0.6), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}
