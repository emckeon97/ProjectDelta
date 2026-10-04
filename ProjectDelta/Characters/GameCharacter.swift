import Foundation

/// A playable character in Project Delta — all public-domain cartoon stars.
struct GameCharacter: Identifiable, Codable, Hashable {
    let id: String          // "willie", "felix", "oswald", "popeye", "pooh", "betty"
    let name: String        // "Steamboat Willie", etc.
    let price: Int          // coins to unlock; 0 = free/starter
    let tagline: String     // one-line flavor text

    static let roster: [GameCharacter] = [
        GameCharacter(
            id: "willie",
            name: "Steamboat Willie",
            price: 0,
            tagline: "The original star — quick on his feet."
        ),
        GameCharacter(
            id: "felix",
            name: "Felix the Cat",
            price: 500,
            tagline: "The mischievous cat keeps his grin."
        ),
        GameCharacter(
            id: "oswald",
            name: "Oswald the Lucky Rabbit",
            price: 1000,
            tagline: "Lucky ears, luckier feet."
        ),
        GameCharacter(
            id: "popeye",
            name: "Popeye the Sailor",
            price: 2500,
            tagline: "Strong to the finish, with spinach to spare."
        ),
        GameCharacter(
            id: "pooh",
            name: "Winnie the Pooh",
            price: 5000,
            tagline: "A bear of very little brain, but big heart."
        ),
        GameCharacter(
            id: "betty",
            name: "Betty Boop",
            price: 10000,
            tagline: "Boop-boop-a-doop!"
        ),
    ]
}
