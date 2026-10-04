import SwiftUI

/// Post-run screen as a classic end card: "THE END" in serif with a
/// decorative double rule, then stats and ticket-styled buttons.
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
        VStack(spacing: 16) {
            Spacer(minLength: 36)

            // The end card.
            VStack(spacing: 10) {
                doubleRule
                Text("THE END")
                    .font(.system(size: 54, weight: .black, design: .serif))
                    .tracking(8)
                    .foregroundColor(DeltaTheme.cream)
                doubleRule
            }
            .padding(.horizontal, 40)

            if isNewBest {
                Text("★ NEW BEST! ★")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundColor(DeltaTheme.ink)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DeltaTheme.gold)
                    )
            }

            statRow(label: "DISTANCE", value: "\(score) m")
            statRow(label: "COINS", value: "🪙 \(coins)")

            #if !targetEnvironment(macCatalyst)
            if !reviveUsed {
                Button {
                    guard let vc = Self.rootViewController() else { return }
                    reviveUsed = true
                    AdManager.shared.showRewarded(from: vc) {
                        onRevive()
                    }
                } label: {
                    Label("ENCORE — WATCH AD", systemImage: "tv")
                }
                .buttonStyle(DeltaButtonStyle())
                .disabled(!ads.isRewardedReady)
                .opacity(ads.isRewardedReady ? 1 : 0.45)
            }
            #endif

            Button("RUN AGAIN", action: onRestart)
                .buttonStyle(DeltaSecondaryButtonStyle())

            Button("MAIN MENU", action: onMenu)
                .buttonStyle(DeltaSecondaryButtonStyle())

            Spacer(minLength: 20)
            AdBannerView()
        }
        .background(DeltaTheme.ink.ignoresSafeArea())
        .onAppear {
            #if !targetEnvironment(macCatalyst)
            AdManager.shared.loadRewarded()
            showInterstitialIfDue()
            #endif
        }
    }

    private var doubleRule: some View {
        VStack(spacing: 3) {
            Rectangle()
                .fill(DeltaTheme.gold.opacity(0.8))
                .frame(height: 2)
            Rectangle()
                .fill(DeltaTheme.gold.opacity(0.8))
                .frame(height: 1)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .tracking(3)
                .foregroundColor(DeltaTheme.cream.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundColor(DeltaTheme.cream)
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
