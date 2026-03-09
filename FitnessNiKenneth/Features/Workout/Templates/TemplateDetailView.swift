import SwiftUI

struct TemplateDetailView: View {

    let template: WorkoutTemplate
    @Environment(WorkoutEngine.self) private var workoutEngine
    @State private var showEditTemplate = false

    var body: some View {
        List {
            Section {
                Button {
                    startWorkout()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.Colors.accent)
                            .clipShape(Circle())

                        Text("Start This Workout")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.primary)

                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                }
            }

            Section("Exercises") {
                ForEach(template.sortedExercises) { templateExercise in
                    TemplateExerciseRow(exercise: templateExercise)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditTemplate = true
                }
            }
        }
        .sheet(isPresented: $showEditTemplate) {
            NavigationStack {
                EditTemplateView(template: template)
            }
        }
    }

    private func startWorkout() {
        let exercises = template.sortedExercises.enumerated().compactMap { index, te -> ActiveExercise? in
            guard let exercise = te.exercise else { return nil }
            var sets: [ActiveSet] = []
            for _ in 0..<te.defaultSets {
                sets.append(ActiveSet(
                    weight: te.defaultWeight,
                    reps: te.defaultReps,
                    unit: te.defaultUnit
                ))
            }
            return ActiveExercise(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                sets: sets,
                restSeconds: te.restSeconds,
                order: index
            )
        }
        workoutEngine.startWorkout(
            name: template.name,
            exercises: exercises,
            templateID: template.id
        )
    }
}

// MARK: - TemplateExerciseRow

struct TemplateExerciseRow: View {
    let exercise: TemplateExercise

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            Text(exercise.exercise?.name ?? "Unknown")
                .font(AppTheme.Typography.body.weight(.medium))

            HStack(spacing: AppTheme.Spacing.regular) {
                Text("\(exercise.defaultSets) sets × \(exercise.defaultReps) reps")
                if exercise.defaultWeight > 0 {
                    Text("@ \(Int(exercise.defaultWeight)) \(exercise.defaultUnit.label)")
                }
            }
            .font(AppTheme.Typography.footnote)
            .foregroundStyle(AppTheme.Colors.secondary)
        }
        .padding(.vertical, AppTheme.Spacing.xxSmall)
    }
}
