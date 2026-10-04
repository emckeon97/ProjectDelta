import SwiftUI

/// Chunky rubber-hose cartoon button — the primary CTA style across the app.
struct DeltaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 44)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.yellow)
                    .shadow(color: .orange, radius: 0, x: 0, y: configuration.isPressed ? 0 : 5)
            )
            .offset(y: configuration.isPressed ? 5 : 0)
    }
}

/// Secondary outline button.
struct DeltaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(configuration.isPressed ? 0.15 : 0.05)))
            )
    }
}

/// Compact button for character grid cells.
struct DeltaSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(configuration.isPressed ? 0.7 : 1))
            )
    }
}

/// Root view: owns the managers and switches between screens.
struct ContentView: View {
    @StateObject private var manager = CharacterManager()
    @StateObject private var ads = AdManager.shared

    enum Screen: Equatable {
        case menu
        case characters
        case game
        case gameOver(score: Int, coins: Int, isNewBest: Bool)
    }

    @State private var screen: Screen = .menu

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch screen {
            case .menu:
                MainMenuView(
                    onPlay: { screen = .game },
                    onCharacters: { screen = .characters }
                )
            case .characters:
                CharacterSelectView(onBack: { screen = .menu })
            case .game:
                GameView(
                    onGameOver: handleGameOver,
                    onQuit: handleQuit
                )
            case .gameOver(let score, let coins, let isNewBest):
                GameOverView(
                    score: score,
                    coins: coins,
                    isNewBest: isNewBest,
                    onRevive: { screen = .game },
                    onRestart: { screen = .game },
                    onMenu: { screen = .menu }
                )
            }
        }
        .environmentObject(manager)
        .environmentObject(ads)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: screen)
        .onAppear {
            #if !targetEnvironment(macCatalyst)
            AdManager.shared.loadInterstitial()
            AdManager.shared.loadRewarded()
            #endif
        }
    }

    private func handleGameOver(score: Int, coins: Int) {
        let isNewBest = manager.recordScore(score)
        if coins > 0 {
            manager.addCoins(coins)
        }
        screen = .gameOver(score: score, coins: coins, isNewBest: isNewBest)
    }

    private func handleQuit(coins: Int) {
        if coins > 0 {
            manager.addCoins(coins)
        }
        screen = .menu
    }
}
