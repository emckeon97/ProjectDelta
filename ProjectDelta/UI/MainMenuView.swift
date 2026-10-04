import SwiftUI
import SpriteKit

/// Live SpriteKit thumbnail of a character — used on the menu and select grid.
struct CharacterPreviewView: View {
    let characterID: String
    private let scene: SKScene

    init(characterID: String) {
        self.characterID = characterID
        let preview = SKScene(size: CGSize(width: 100, height: 130))
        preview.backgroundColor = .clear
        preview.scaleMode = .aspectFit
        let node = CharacterRenderer.node(for: characterID)
        // Renderer anchors the node at feet-center; sit it near the bottom.
        node.position = CGPoint(x: 50, y: 6)
        preview.addChild(node)
        self.scene = preview
    }

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
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
