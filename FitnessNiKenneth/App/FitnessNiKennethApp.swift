import SwiftUI
import SwiftData
import UserNotifications

@main
struct FitnessNiKennethApp: App {

    @State private var workoutEngine = WorkoutEngine()
    @State private var watchService = WatchConnectivityService.shared

    private let notificationDelegate = AppNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(workoutEngine)
                .environment(watchService)
                .task {
                    await NotificationService.requestPermission()
                }
        }
        .modelContainer(for: appSchema, isAutosaveEnabled: true) { result in
            switch result {
            case .success(let container):
                SeedDataService.seedIfNeeded(context: container.mainContext)
                watchService.activate()
                workoutEngine.setWatchUpdateHandler { session, elapsed, restRemaining, isResting in
                    watchService.sendWorkoutUpdate(
                        session: session,
                        elapsedSeconds: elapsed,
                        restSecondsRemaining: restRemaining,
                        isResting: isResting
                    )
                }
            case .failure(let error):
                print("SwiftData container failed: \(error)")
            }
        }
    }

    private var appSchema: [any PersistentModel.Type] {
        [
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            WorkoutSession.self,
            WorkoutExercise.self,
            WorkoutSet.self,
        ]
    }
}
