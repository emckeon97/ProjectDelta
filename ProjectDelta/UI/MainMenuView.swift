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

/// Main menu: 1930s movie-poster marquee.
struct MainMenuView: View {
    @EnvironmentObject private var manager: CharacterManager
    @ObservedObject private var music = MusicManager.shared
    var onPlay: () -> Void
    var onCharacters: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            Text("NOW SHOWING")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .tracking(6)
                .foregroundColor(DeltaTheme.cream.opacity(0.75))

            MarqueeLights()
                .padding(.vertical, 10)

            Text("PROJECT DELTA")
                .font(.system(size: 44, weight: .black, design: .serif))
                .tracking(2)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .foregroundColor(DeltaTheme.cream)
                .padding(.horizontal, 20)

            Text("A STEAMBOAT CARTOON")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .tracking(5)
                .foregroundColor(DeltaTheme.gold)
                .padding(.top, 8)

            CharacterPreviewView(characterID: manager.selectedID)
                .frame(width: 110, height: 140)
                .padding(.top, 14)
            Text(manager.selectedCharacter.name.uppercased())
                .font(.system(size: 15, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundColor(DeltaTheme.cream.opacity(0.9))

            Spacer(minLength: 14)

            HStack(spacing: 16) {
                statPill(value: "🪙 \(manager.coins)")
                statPill(value: "🏆 \(manager.highScore) m")
            }
            .padding(.bottom, 18)

            Button(action: onPlay) {
                VStack(spacing: 3) {
                    Text("★ ADMIT ONE ★")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .tracking(3)
                    Text("PLAY")
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .tracking(5)
                }
                .foregroundColor(DeltaTheme.ink)
                .padding(.horizontal, 54)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DeltaTheme.gold)
                        .shadow(color: DeltaTheme.gold.opacity(0.35), radius: 12)
                )
            }
            .padding(.bottom, 12)

            Button(action: onCharacters) {
                Text("MEET THE STARS")
            }
            .buttonStyle(DeltaSecondaryButtonStyle())

            Spacer(minLength: 12)

            // Billing block — the full roster, movie-poster style.
            Text(manager.characters.map { $0.name.uppercased() }.joined(separator: "   •   "))
                .font(.system(size: 9, weight: .medium, design: .serif))
                .tracking(1)
                .foregroundColor(DeltaTheme.cream.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 28)
                .padding(.bottom, 8)

            Text("Music: “The Entertainer” by Kevin MacLeod (incompetech.com) · CC BY 4.0")
                .font(.system(size: 9))
                .foregroundColor(DeltaTheme.cream.opacity(0.35))
                .padding(.bottom, 6)

            AdBannerView()
        }
        .background(DeltaTheme.ink.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button {
                music.toggleMute()
            } label: {
                Image(systemName: music.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .foregroundColor(DeltaTheme.gold)
                    .padding(12)
                    .background(DeltaTheme.cream.opacity(0.06))
                    .cornerRadius(12)
            }
            .padding(.top, 54)
            .padding(.trailing, 16)
        }
    }

    private func statPill(value: String) -> some View {
        Text(value)
            .font(.system(size: 17, weight: .bold, design: .serif))
            .foregroundColor(DeltaTheme.gold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(DeltaTheme.cream.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DeltaTheme.gold.opacity(0.35), lineWidth: 1)
            )
    }
}
