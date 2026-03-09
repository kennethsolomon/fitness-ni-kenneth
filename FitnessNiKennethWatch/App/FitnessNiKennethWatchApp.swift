import SwiftUI

@main
struct FitnessNiKennethWatchApp: App {

    @State private var watchEngine = WatchWorkoutEngine()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(watchEngine)
        }
    }
}
