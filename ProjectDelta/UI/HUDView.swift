import SwiftUI

/// In-game top bar: live score (left), run coins (right), pause button.
/// The container is transparent to touches except for the pause button,
/// so swipe gestures reach the scene below. Sepia-toned to match the
/// 1930s marquee theme.
struct HUDView: View {
    let score: Int
    let coins: Int
    var onPause: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                pill(text: "\(score) m")
                Spacer()
                pill(text: "🪙 \(coins)")

                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .foregroundColor(DeltaTheme.cream)
                        .padding(10)
                        .background(Color(red: 0.10, green: 0.08, blue: 0.06).opacity(0.65))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()
                .allowsHitTesting(false)
        }
    }

    private func pill(text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .black, design: .serif))
            .foregroundColor(DeltaTheme.cream)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(red: 0.10, green: 0.08, blue: 0.06).opacity(0.65))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DeltaTheme.gold.opacity(0.25), lineWidth: 1)
            )
            .allowsHitTesting(false)
    }
}
