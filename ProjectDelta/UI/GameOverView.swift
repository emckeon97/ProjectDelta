import SwiftUI

/// Post-run screen: score, coins, revive (rewarded ad), restart, menu.
/// Shows an interstitial ad on every 3rd game over (see showInterstitialIfDue).
struct GameOverView: View {
    let score: Int
    let coins: Int
    let isNewBest: Bool
    var onRevive: () -> Void
    var onRestart: () -> Void
    var onMenu: () -> Void

    #if !targetEnvironment(macCatalyst)
    @ObservedObject private var ads = AdManager.shared
    #endif
    @State private var reviveUsed = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 32)

            Text("WIPED OUT!")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .italic()
                .foregroundColor(.red)

            if isNewBest {
                Text("★ NEW BEST! ★")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.14))
                    .cornerRadius(12)
            }

            statRow(label: "Distance", value: "\(score) m")
            statRow(label: "Coins", value: "🪙 \(coins)")

            #if !targetEnvironment(macCatalyst)
            if !reviveUsed {
                Button {
                    guard let vc = Self.rootViewController() else { return }
                    reviveUsed = true
                    AdManager.shared.showRewarded(from: vc) {
                        onRevive()
                    }
                } label: {
                    Label("Revive — watch ad", systemImage: "tv")
                }
                .buttonStyle(DeltaButtonStyle())
                .disabled(!ads.isRewardedReady)
                .opacity(ads.isRewardedReady ? 1 : 0.45)
            }
            #endif

            Button("Run Again", action: onRestart)
                .buttonStyle(DeltaButtonStyle())

            Button("Main Menu", action: onMenu)
                .buttonStyle(DeltaSecondaryButtonStyle())

            Spacer(minLength: 24)
            AdBannerView()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            #if !targetEnvironment(macCatalyst)
            AdManager.shared.loadRewarded()
            showInterstitialIfDue()
            #endif
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.65))
            Spacer()
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
        }
        .padding(.horizontal, 52)
    }

    #if !targetEnvironment(macCatalyst)
    /// Interstitial on every 3rd game over, preloading the next one after a show.
    private func showInterstitialIfDue() {
        let key = "delta.gameOverCount"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)
        guard count % 3 == 0, let vc = Self.rootViewController() else { return }
        _ = AdManager.shared.showInterstitial(from: vc)
        AdManager.shared.loadInterstitial()
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?
            .rootViewController
    }
    #endif
}
