import SwiftUI

struct RootTabView: View {

    @Environment(WorkoutEngine.self) private var workoutEngine
    @State private var selectedTab = 0
    @State private var showActiveWorkout = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("History", systemImage: "clock.fill", value: 0) {
                NavigationStack {
                    HistoryView()
                }
            }

            Tab("Workout", systemImage: "dumbbell.fill", value: 1) {
                NavigationStack {
                    StartWorkoutView()
                }
            }

            Tab("Exercises", systemImage: "figure.strengthtraining.traditional", value: 2) {
                NavigationStack {
                    ExerciseListView()
                }
            }
        }
        .sheet(isPresented: $showActiveWorkout) {
            ActiveWorkoutView()
        }
        .onChange(of: workoutEngine.isActive) { _, isActive in
            if isActive { showActiveWorkout = true }
        }
        .onAppear {
            if workoutEngine.isActive { showActiveWorkout = true }
        }
    }
}
