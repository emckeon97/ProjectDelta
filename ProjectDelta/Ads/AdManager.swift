//
//  AdManager.swift
//  Pier Pressure
//
//  Google Mobile Ads (AdMob) integration — written against GMA iOS SDK v13
//  Swift API naming (GAD prefixes removed in v12).
//  - Banner: bottom of menu / character-select screens.
//  - Interstitial: every 3rd game over, max once per 60 seconds.
//  - Rewarded: "revive" continue after a crash.
//
//  DEVELOPMENT: uses Google's official test ad unit IDs (useTestIDs = true).
//  Test ads are REQUIRED during development — real impressions from a dev
//  build will get the AdMob account flagged.
//  PRODUCTION: set useTestIDs = false and paste the real unit IDs into
//  REAL_BANNER_ID / REAL_INTERSTITIAL_ID / REAL_REWARDED_ID.
//
//  The AdMob APP ID (ca-app-pub-3940256099942544~1458002511 for tests)
//  belongs in Info.plist under the GADApplicationIdentifier key — not here.
//
//  Mac Catalyst: Google Mobile Ads does not link on Catalyst, so every SDK
//  reference is behind #if !targetEnvironment(macCatalyst) and the class
//  compiles to safe no-ops there.

import Combine
import UIKit

#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
#endif

final class AdManager: NSObject, ObservableObject {

    static let shared = AdManager()

    // MARK: - Ad unit IDs

    /// Flip to false and fill in REAL_* below when production units are created.
    static let useTestIDs = true

    static let REAL_BANNER_ID = ""
    static let REAL_INTERSTITIAL_ID = ""
    static let REAL_REWARDED_ID = ""

    // Google's official sample IDs — safe for development.
    private static let TEST_BANNER_ID = "ca-app-pub-3940256099942544/2934735716"
    private static let TEST_INTERSTITIAL_ID = "ca-app-pub-3940256099942544/4411468910"
    private static let TEST_REWARDED_ID = "ca-app-pub-3940256099942544/1712485313"

    private static var bannerID: String {
        useTestIDs ? TEST_BANNER_ID : REAL_BANNER_ID
    }
    private static var interstitialID: String {
        useTestIDs ? TEST_INTERSTITIAL_ID : REAL_INTERSTITIAL_ID
    }
    private static var rewardedID: String {
        useTestIDs ? TEST_REWARDED_ID : REAL_REWARDED_ID
    }

    // MARK: - Published state

    @Published var isInterstitialReady = false
    @Published var isRewardedReady = false

    /// True when any ad is loaded and ready to show. Always false on Catalyst.
    var isAdReady: Bool { isInterstitialReady || isRewardedReady }

    // MARK: - Interstitial pacing

    private var gameOverCount = 0
    private var lastInterstitialShownAt: Date?

    #if !targetEnvironment(macCatalyst)
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var pendingRewardHandler: (() -> Void)?
    #endif

    // MARK: - Init

    override init() {
        super.init()
        #if !targetEnvironment(macCatalyst)
        MobileAds.shared.start()
        loadInterstitial()
        loadRewarded()
        #endif
    }

    // MARK: - Banner

    /// Returns a view controller hosting a 320x50 banner that loads on appear.
    /// The banner uses the returned controller as its GAD root view controller,
    /// so callers never pass a view controller in.
    func makeBannerViewController() -> UIViewController {
        #if !targetEnvironment(macCatalyst)
        let vc = AdBannerViewController()
        vc.adUnitID = Self.bannerID
        return vc
        #else
        return UIViewController()
        #endif
    }

    /// Convenience alias used by AdBannerView.
    func makeBanner() -> UIViewController { makeBannerViewController() }

    // MARK: - Interstitial

    func loadInterstitial() {
        #if !targetEnvironment(macCatalyst)
        let id = Self.interstitialID
        guard !id.isEmpty else { return }
        InterstitialAd.load(with: id, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let ad {
                    ad.fullScreenContentDelegate = self
                    self.interstitialAd = ad
                    self.isInterstitialReady = true
                } else {
                    self.isInterstitialReady = false
                }
            }
        }
        #endif
    }

    /// Presents the interstitial if one is loaded and the 60-second cooldown
    /// has elapsed since the last presentation. Returns true if presented.
    @discardableResult
    func showInterstitial(from rootViewController: UIViewController) -> Bool {
        #if !targetEnvironment(macCatalyst)
        if let last = lastInterstitialShownAt,
           Date().timeIntervalSince(last) < 60 {
            return false
        }
        guard let ad = interstitialAd else { return false }
        lastInterstitialShownAt = Date()
        interstitialAd = nil
        isInterstitialReady = false
        ad.present(from: rootViewController)
        return true
        #else
        return false
        #endif
    }

    /// Call on every game over. Shows an interstitial on every 3rd game over
    /// (subject to the 60-second cooldown) and keeps the next one preloading
    /// otherwise. Finds the presenting view controller internally.
    /// Every 5th game over shows an interstitial — frequent enough to earn,
    /// rare enough to keep players.
    func gameOverOccurred() {
        gameOverCount += 1
        #if !targetEnvironment(macCatalyst)
        guard gameOverCount % 5 == 0 else {
            if interstitialAd == nil { loadInterstitial() }
            return
        }
        if let rootVC = Self.topViewController(), showInterstitial(from: rootVC) {
            // The next ad preloads in adDidDismissFullScreenContent.
        } else {
            loadInterstitial()
        }
        #endif
    }

    // MARK: - Rewarded

    func loadRewarded() {
        #if !targetEnvironment(macCatalyst)
        let id = Self.rewardedID
        guard !id.isEmpty else { return }
        RewardedAd.load(with: id, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let ad {
                    ad.fullScreenContentDelegate = self
                    self.rewardedAd = ad
                    self.isRewardedReady = true
                } else {
                    self.isRewardedReady = false
                }
            }
        }
        #endif
    }

    /// Presents the rewarded ad. `onReward` fires on the main thread when the
    /// user earns the reward. No-op when no ad is loaded.
    func showRewarded(from rootViewController: UIViewController, onReward: @escaping () -> Void) {
        #if !targetEnvironment(macCatalyst)
        guard let ad = rewardedAd else { return }
        pendingRewardHandler = onReward
        rewardedAd = nil
        isRewardedReady = false
        ad.present(from: rootViewController) { [weak self] in
            DispatchQueue.main.async {
                self?.pendingRewardHandler?()
                self?.pendingRewardHandler = nil
            }
        }
        #endif
    }

    // MARK: - Helpers

    /// Walks up to the topmost presented view controller, so internally
    /// triggered ads never require callers to pass a view controller.
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let window = scenes.first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else {
            return nil
        }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - FullScreenContentDelegate (iOS only)

#if !targetEnvironment(macCatalyst)
extension AdManager: FullScreenContentDelegate {

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Preload the next ad as soon as one is dismissed.
            if ad is InterstitialAd {
                self.loadInterstitial()
            } else if ad is RewardedAd {
                self.loadRewarded()
            }
        }
    }

    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if ad is InterstitialAd {
                self.interstitialAd = nil
                self.isInterstitialReady = false
                self.loadInterstitial()
            } else if ad is RewardedAd {
                self.rewardedAd = nil
                self.isRewardedReady = false
                self.pendingRewardHandler = nil
                self.loadRewarded()
            }
        }
    }
}

// MARK: - Banner host view controller (iOS only)

private final class AdBannerViewController: UIViewController, BannerViewDelegate {

    var adUnitID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = self
        banner.delegate = self
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            banner.widthAnchor.constraint(equalToConstant: AdSizeBanner.size.width),
            banner.heightAnchor.constraint(equalToConstant: AdSizeBanner.size.height),
        ])
        banner.load(Request())
    }

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        bannerView.alpha = 0
        UIView.animate(withDuration: 0.25) { bannerView.alpha = 1 }
    }
}
#endif
