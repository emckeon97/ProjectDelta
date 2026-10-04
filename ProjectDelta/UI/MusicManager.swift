import AVFoundation
import Combine

/// Background music: "The Entertainer" (Kevin MacLeod, CC-BY 4.0).
/// Loops forever at low volume on the .ambient session (mixes with other audio).
/// The MP3 (delta_ragtime.mp3) is bundled with the Xcode target separately;
/// every method here is a safe no-op if the file is missing.
final class MusicManager: ObservableObject {
    static let shared = MusicManager()

    @Published var isMuted: Bool {
        didSet { UserDefaults.standard.set(isMuted, forKey: "delta.musicMuted") }
    }

    private var player: AVAudioPlayer?

    private init() {
        isMuted = UserDefaults.standard.bool(forKey: "delta.musicMuted")
    }

    /// Starts the loop (or resumes after unmute). Safe to call repeatedly.
    func play() {
        guard !isMuted else { return }
        if player == nil {
            guard let url = Bundle.main.url(forResource: "delta_ragtime", withExtension: "mp3") else { return }
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                let p = try AVAudioPlayer(contentsOf: url)
                p.numberOfLoops = -1
                p.volume = 0.45
                p.prepareToPlay()
                player = p
            } catch {
                return
            }
        }
        player?.play()
    }

    func stop() {
        player?.stop()
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            player?.pause()
        } else {
            play()
        }
    }
}
