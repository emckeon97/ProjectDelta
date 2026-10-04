import Foundation
import Combine

/// Owns the character roster, coin wallet, unlocks, selection, and high score.
/// Persisted to UserDefaults so progress survives app restarts.
@MainActor
final class CharacterManager: ObservableObject {
    @Published private(set) var coins: Int
    @Published private(set) var selectedID: String
    @Published private(set) var unlockedIDs: Set<String>
    @Published private(set) var highScore: Int

    var characters: [GameCharacter] { GameCharacter.roster }

    var selectedCharacter: GameCharacter {
        characters.first(where: { $0.id == selectedID }) ?? characters[0]
    }

    init() {
        let defaults = UserDefaults.standard
        self.coins = defaults.integer(forKey: Self.coinsKey)
        let savedSelected = defaults.string(forKey: Self.selectedKey)
        let savedUnlocked = defaults.stringArray(forKey: Self.unlockedKey) ?? []
        self.unlockedIDs = Set(savedUnlocked)
        self.highScore = defaults.integer(forKey: Self.highScoreKey)

        // Willie is always available.
        self.unlockedIDs.insert("willie")

        if let savedSelected, GameCharacter.roster.contains(where: { $0.id == savedSelected }) {
            self.selectedID = savedSelected
        } else {
            self.selectedID = "willie"
        }
    }

    func isUnlocked(_ character: GameCharacter) -> Bool {
        unlockedIDs.contains(character.id)
    }

    /// Spends coins to unlock. Returns false if already unlocked or can't afford.
    @discardableResult
    func unlock(_ character: GameCharacter) -> Bool {
        guard !isUnlocked(character), coins >= character.price else { return false }
        coins -= character.price
        unlockedIDs.insert(character.id)
        save()
        return true
    }

    /// Selects a character — no-op unless it's unlocked.
    func select(_ character: GameCharacter) {
        guard isUnlocked(character) else { return }
        selectedID = character.id
        save()
    }

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
        save()
    }

    /// Records a run score; returns true when it's a new high score.
    @discardableResult
    func recordScore(_ score: Int) -> Bool {
        guard score > highScore else { return false }
        highScore = score
        save()
        return true
    }

    // MARK: - Persistence

    private static let coinsKey = "delta.coins"
    private static let selectedKey = "delta.selected"
    private static let unlockedKey = "delta.unlocked"
    private static let highScoreKey = "delta.highscore"

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(coins, forKey: Self.coinsKey)
        defaults.set(selectedID, forKey: Self.selectedKey)
        defaults.set(Array(unlockedIDs), forKey: Self.unlockedKey)
        defaults.set(highScore, forKey: Self.highScoreKey)
    }
}
