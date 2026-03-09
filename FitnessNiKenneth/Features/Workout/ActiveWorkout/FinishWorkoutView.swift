import SwiftUI
import SwiftData

struct FinishWorkoutView: View {

    let session: ActiveSession
    @Environment(WorkoutEngine.self) private var workoutEngine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var allSessions: [WorkoutSession]

    @State private var didFinish = false

    var body: some View {
        List {
            Section {
                summarySection
            }

            Section("Exercises") {
                ForEach(session.exercises) { exercise in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                        Text(exercise.exerciseName)
                            .font(AppTheme.Typography.headline)

                        let completed = exercise.sets.filter(\.isCompleted)
                        Text("\(completed.count)/\(exercise.sets.count) sets completed")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.secondary)
                    }
                    .padding(.vertical, AppTheme.Spacing.xxSmall)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Finish Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    finishWorkout()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.accent)
            }
        }
    }

    private var summarySection: some View {
        VStack(spacing: AppTheme.Spacing.regular) {
            HStack(spacing: AppTheme.Spacing.xxLarge) {
                StatCell(
                    label: "Duration",
                    value: workoutEngine.elapsedSeconds.workoutTimerFormatted
                )
                Divider().frame(height: 40)
                StatCell(
                    label: "Exercises",
                    value: "\(session.exercises.count)"
                )
                Divider().frame(height: 40)
                StatCell(
                    label: "Sets",
                    value: "\(session.exercises.flatMap(\.sets).filter(\.isCompleted).count)"
                )
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }

    private func finishWorkout() {
        _ = workoutEngine.finishWorkout(context: context)
        dismiss()
    }
}
