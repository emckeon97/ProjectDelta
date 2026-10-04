import SwiftUI

/// In-game top bar: live score (left), run coins (right), pause button.
/// The container is transparent to touches except for the pause button,
/// so swipe gestures reach the SpriteKit view below.
struct HUDView: View {
    let score: Int
    let coins: Int
    var onPause: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("\(score) m")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.55))
                    .cornerRadius(12)
                    .allowsHitTesting(false)

                Spacer()

                Text("🪙 \(coins)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.55))
                    .cornerRadius(12)
                    .allowsHitTesting(false)

                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()
                .allowsHitTesting(false)
        }
    }
}
