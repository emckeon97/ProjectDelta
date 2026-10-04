import SwiftUI

/// Character roster grid: preview, name, tagline, unlock/select actions.
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
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                Text("CHOOSE YOUR STAR")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("🪙 \(manager.coins)")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }
            .padding()

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
        .background(Color.black.ignoresSafeArea())
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
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

            Text(character.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(character.tagline)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 34)

            actionButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.yellow.opacity(0.14) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var actionButton: some View {
        if manager.isUnlocked(character) {
            if isSelected {
                Text("✓ SELECTED")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.green)
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
