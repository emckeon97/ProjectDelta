import SwiftUI

@main
struct ProjectDeltaApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            // Never play audio in the background.
            switch phase {
            case .background:
                MusicManager.shared.pause()
            case .active:
                MusicManager.shared.play()
            default:
                break
            }
        }
    }
}
