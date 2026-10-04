import SwiftUI

/// 1930s cartoon-marquee palette.
enum DeltaTheme {
    static let ink   = Color(red: 0.039, green: 0.039, blue: 0.047) // #0A0A0C
    static let cream = Color(red: 0.961, green: 0.937, blue: 0.878) // #F5EFE0
    static let gold  = Color(red: 0.831, green: 0.663, blue: 0.259)  // #D4A942
    static let red   = Color(red: 0.690, green: 0.227, blue: 0.180)  // #B03A2E
}

/// A row of marquee chase lights — some lit, some dimmed.
struct MarqueeLights: View {
    var count: Int = 18

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<count, id: \.self) { i in
                let lit = i % 3 != 0
                Circle()
                    .fill(lit ? DeltaTheme.gold : DeltaTheme.gold.opacity(0.22))
                    .frame(width: 7, height: 7)
                    .shadow(color: lit ? DeltaTheme.gold.opacity(0.9) : .clear, radius: 5)
            }
        }
    }
}

/// Gold ticket-stub primary button.
struct DeltaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .black, design: .serif))
            .tracking(2)
            .foregroundColor(DeltaTheme.ink)
            .padding(.horizontal, 44)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DeltaTheme.gold)
                    .shadow(color: DeltaTheme.gold.opacity(0.35), radius: configuration.isPressed ? 0 : 10, x: 0, y: configuration.isPressed ? 0 : 4)
            )
            .offset(y: configuration.isPressed ? 4 : 0)
    }
}

/// Cream outline secondary button.
struct DeltaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .serif))
            .tracking(1)
            .foregroundColor(DeltaTheme.cream)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DeltaTheme.cream.opacity(0.5), lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 10).fill(DeltaTheme.cream.opacity(configuration.isPressed ? 0.15 : 0.04)))
            )
    }
}

/// Compact gold button for character grid cells.
struct DeltaSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black, design: .serif))
            .tracking(1)
            .foregroundColor(DeltaTheme.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DeltaTheme.gold.opacity(configuration.isPressed ? 0.7 : 1))
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
            DeltaTheme.ink.ignoresSafeArea()

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
            MusicManager.shared.play()
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
