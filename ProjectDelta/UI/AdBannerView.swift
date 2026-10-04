import SwiftUI

/// Bottom banner ad. On Mac Catalyst (Google Mobile Ads has no Catalyst slice)
/// this renders as an empty spacer so layouts don't shift between targets.
struct AdBannerView: View {
    var body: some View {
        #if targetEnvironment(macCatalyst)
        Spacer()
            .frame(height: 50)
        #else
        AdBannerRepresentable()
            .frame(height: 50)
        #endif
    }
}

#if !targetEnvironment(macCatalyst)
/// Hosts the AdMob banner view controller built by AdManager (see BUILD_SPEC.md).
private struct AdBannerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        AdManager.shared.makeBanner()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif
