import Foundation

/// A playable character in Project Delta — all public-domain cartoon stars.
struct GameCharacter: Identifiable, Codable, Hashable {
    let id: String          // "willie", "felix", "pete", ... (12 total)
    let name: String        // "Steamboat Willie", etc.
    let price: Int          // coins to unlock; 0 = free/starter
    let tagline: String     // one-line flavor text

    static let roster: [GameCharacter] = [
        GameCharacter(
            id: "willie",
            name: "Mickey Mouse",
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
            id: "minnie",
            name: "Minnie Mouse",
            price: 1500,
            tagline: "Steamboat sweetheart, quick on her feet."
        ),
        GameCharacter(
            id: "popeye",
            name: "Popeye the Sailor",
            price: 2500,
            tagline: "Strong to the finish, with spinach to spare."
        ),
        GameCharacter(
            id: "koko",
            name: "Koko the Clown",
            price: 3000,
            tagline: "Straight out of the inkwell."
        ),
        GameCharacter(
            id: "bimbo",
            name: "Bimbo",
            price: 4000,
            tagline: "Betty's best pal, always up for a run."
        ),
        GameCharacter(
            id: "pooh",
            name: "Winnie the Pooh",
            price: 5000,
            tagline: "A bear of very little brain, but big heart."
        ),
        GameCharacter(
            id: "olive",
            name: "Olive Oyl",
            price: 6500,
            tagline: "Tall, quick, and never still."
        ),
        GameCharacter(
            id: "bosko",
            name: "Bosko",
            price: 8000,
            tagline: "The talk-ink kid himself."
        ),
        GameCharacter(
            id: "betty",
            name: "Betty Boop",
            price: 10000,
            tagline: "Boop-boop-a-doop!"
        ),
        GameCharacter(
            id: "pete",
            name: "Peg-Leg Pete",
            price: 12000,
            tagline: "The river's meanest captain. Mind the peg leg."
        ),
    ]
}
