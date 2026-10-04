import SwiftUI
import SceneKit

/// Live 3D thumbnail of a character — SceneKit preview with a slow turntable.
/// Used on the menu and the character-select grid.
struct CharacterPreviewView: View {
    let characterID: String

    var body: some View {
        CharacterPreviewRepresentable(characterID: characterID)
    }
}

private struct CharacterPreviewRepresentable: UIViewRepresentable {
    let characterID: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.allowsCameraControl = false
        view.isPlaying = true
        view.antialiasingMode = .multisampling4X
        view.scene = makeScene()
        context.coordinator.lastID = characterID
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard context.coordinator.lastID != characterID else { return }
        context.coordinator.lastID = characterID
        uiView.scene = makeScene()
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()

        let node = CharacterRenderer.node(for: characterID)
        node.runAction(.repeatForever(
            .rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 6)
        ))
        scene.rootNode.addChildNode(node)

        let target = SCNNode()
        target.position = SCNVector3(0, 0.9, 0)
        scene.rootNode.addChildNode(target)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 1.0, 3.2)
        camera.constraints = [SCNLookAtConstraint(target: target)]
        scene.rootNode.addChildNode(camera)

        let ambient = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 800
        ambient.light = ambientLight
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 1400
        key.light = keyLight
        key.eulerAngles = SCNVector3(-0.6, 0.3, 0)
        scene.rootNode.addChildNode(key)

        return scene
    }

    final class Coordinator {
        var lastID: String?
    }
}

/// Main menu: title, selected character, stats, Play / Characters, banner ad.
struct MainMenuView: View {
    @EnvironmentObject private var manager: CharacterManager
    var onPlay: () -> Void
    var onCharacters: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Text("PROJECT")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .italic()
                .foregroundColor(.white)
            Text("DELTA")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .italic()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("starring public-domain legends")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))
                .padding(.top, 6)

            CharacterPreviewView(characterID: manager.selectedID)
                .frame(width: 110, height: 140)
                .padding(.top, 20)
            Text(manager.selectedCharacter.name)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Spacer(minLength: 16)

            HStack(spacing: 16) {
                statPill(icon: "🪙", value: "\(manager.coins)")
                statPill(icon: "🏆", value: "\(manager.highScore) m")
            }
            .padding(.bottom, 20)

            Button(action: onPlay) {
                Text("▶  PLAY")
            }
            .buttonStyle(DeltaButtonStyle())
            .padding(.bottom, 12)

            Button(action: onCharacters) {
                Text("Characters")
            }
            .buttonStyle(DeltaSecondaryButtonStyle())

            Spacer(minLength: 16)
            AdBannerView()
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func statPill(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(icon)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }
}
