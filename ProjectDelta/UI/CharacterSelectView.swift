import SwiftUI

/// Character roster grid: marquee title, cream-and-gold cells on dark.
struct CharacterSelectView: View {
    @EnvironmentObject private var manager: CharacterManager
    var onBack: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(DeltaTheme.cream)
                        .padding(10)
                        .background(DeltaTheme.cream.opacity(0.08))
                        .cornerRadius(12)
                }
                Spacer()
                Text("🪙 \(manager.coins)")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(DeltaTheme.gold)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            MarqueeLights(count: 14)
                .padding(.top, 10)

            Text("CHOOSE YOUR STAR")
                .font(.system(size: 24, weight: .black, design: .serif))
                .tracking(3)
                .foregroundColor(DeltaTheme.cream)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(manager.characters) { character in
                        CharacterCellView(character: character)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            AdBannerView()
        }
        .background(DeltaTheme.ink.ignoresSafeArea())
    }
}

private struct CharacterCellView: View {
    @EnvironmentObject private var manager: CharacterManager
    let character: GameCharacter

    private var isSelected: Bool { manager.selectedID == character.id }

    var body: some View {
        VStack(spacing: 8) {
            CharacterPreviewView(characterID: character.id)
                .frame(width: 100, height: 130)
                .background(DeltaTheme.cream.opacity(0.04))
                .cornerRadius(12)

            Text(character.name.uppercased())
                .font(.system(size: 14, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(DeltaTheme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(character.tagline)
                .font(.caption)
                .foregroundColor(DeltaTheme.cream.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 34)

            actionButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? DeltaTheme.gold.opacity(0.12) : DeltaTheme.cream.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? DeltaTheme.gold : DeltaTheme.cream.opacity(0.12), lineWidth: isSelected ? 2 : 1)
        )
    }

    @ViewBuilder
    private var actionButton: some View {
        if manager.isUnlocked(character) {
            if isSelected {
                Text("★ STARRING ★")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .tracking(1)
                    .foregroundColor(DeltaTheme.gold)
                    .padding(.vertical, 9)
            } else {
                Button("SELECT") { manager.select(character) }
                    .buttonStyle(DeltaSmallButtonStyle())
            }
        } else {
            let affordable = manager.coins >= character.price
            Button("🔓 \(character.price)") {
                _ = manager.unlock(character)
            }
            .buttonStyle(DeltaSmallButtonStyle())
            .disabled(!affordable)
            .opacity(affordable ? 1 : 0.45)
        }
    }
}
