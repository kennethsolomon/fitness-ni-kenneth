import SwiftUI

struct ActiveExerciseSection: View {

    let exercise: ActiveExercise
    let allSessions: [WorkoutSession]

    @Environment(WorkoutEngine.self) private var workoutEngine
    @State private var showNotes = false
    @State private var showReplaceExercise = false
    @State private var showRestOptions = false

    var body: some View {
        VStack(spacing: 0) {
            exerciseHeader
            Divider().padding(.horizontal, AppTheme.Spacing.regular)
            columnHeader
            Divider().padding(.horizontal, AppTheme.Spacing.regular)

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                ActiveSetRow(
                    set: set,
                    setNumber: index + 1,
                    exerciseID: exercise.id,
                    previousPerformance: previousSet(for: index),
                    isPR: isPR(for: set)
                )
                .padding(.horizontal, AppTheme.Spacing.regular)

                if index < exercise.sets.count - 1 {
                    Divider()
                        .padding(.horizontal, AppTheme.Spacing.regular)
                }
            }

            addSetButton
        }
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var exerciseHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName)
                    .font(AppTheme.Typography.headline)

                if workoutEngine.isResting && workoutEngine.activeRestExerciseID == exercise.id {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(AppTheme.Typography.caption)
                        Text(workoutEngine.restSecondsRemaining.restTimerFormatted)
                            .font(AppTheme.Typography.caption.monospacedDigit())
                    }
                    .foregroundStyle(AppTheme.Colors.restTimerActive)
                } else {
                    Text("Rest: \(exercise.restSeconds.restTimerFormatted)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondary)
                }
            }

            Spacer()

            Menu {
                Button {
                    showNotes = true
                } label: {
                    Label("Notes", systemImage: "note.text")
                }

                Button {
                    showRestOptions = true
                } label: {
                    Label("Set Rest Timer", systemImage: "timer")
                }

                Button {
                    showReplaceExercise = true
                } label: {
                    Label("Replace Exercise", systemImage: "arrow.triangle.2.circlepath")
                }

                Button(role: .destructive) {
                    workoutEngine.removeExercise(id: exercise.id)
                } label: {
                    Label("Remove Exercise", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.regular)
        .padding(.vertical, AppTheme.Spacing.medium)
        .sheet(isPresented: $showNotes) {
            ExerciseNotesSheet(exercise: exercise)
        }
        .sheet(isPresented: $showReplaceExercise) {
            NavigationStack {
                ExercisePickerView(excludedIDs: [exercise.exerciseID]) { newExercise in
                    workoutEngine.replaceExercise(
                        id: exercise.id,
                        with: newExercise.id,
                        exerciseName: newExercise.name
                    )
                }
            }
        }
        .confirmationDialog("Set Rest Timer", isPresented: $showRestOptions) {
            ForEach([30, 60, 90, 120, 180, 240, 300], id: \.self) { seconds in
                Button(seconds.restTimerFormatted) {
                    workoutEngine.updateExerciseRestTime(id: exercise.id, seconds: seconds)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var columnHeader: some View {
        HStack {
            Text("SET")
                .frame(width: 36)
            Spacer()
            Text("PREVIOUS")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("LBS")
                .frame(width: 72, alignment: .center)
            Text("REPS")
                .frame(width: 60, alignment: .center)
            Text("")
                .frame(width: 36)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppTheme.Colors.secondary)
        .tracking(0.5)
        .padding(.horizontal, AppTheme.Spacing.regular)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.tertiaryBackground)
    }

    private var addSetButton: some View {
        Button {
            withAnimation(AppTheme.Animation.spring) {
                workoutEngine.addSet(to: exercise.id)
            }
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(AppTheme.Typography.subheadline)
                Text("Add Set")
                    .font(AppTheme.Typography.subheadline)
            }
            .foregroundStyle(AppTheme.Colors.accent)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.medium)
        }
        .buttonStyle(.plain)
    }

    private func previousSet(for index: Int) -> WorkoutSetSnapshot? {
        let prevPerf = AnalyticsService.previousPerformance(
            exerciseID: exercise.exerciseID,
            before: Date(),
            in: allSessions
        )
        return prevPerf.indices.contains(index) ? prevPerf[index] : nil
    }

    private func isPR(for set: ActiveSet) -> Bool {
        guard set.isCompleted, set.reps > 0, set.weight > 0 else { return false }
        let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: set.weight, reps: set.reps)
        let historicalBest = AnalyticsService.bestSet(for: exercise.exerciseID, in: allSessions)
        let bestOneRM = historicalBest.map {
            AnalyticsFormulas.epleyOneRepMax(weight: $0.weight, reps: $0.reps)
        } ?? 0
        return oneRM > bestOneRM
    }
}

// MARK: - ExerciseNotesSheet

struct ExerciseNotesSheet: View {
    let exercise: ActiveExercise
    @Environment(WorkoutEngine.self) private var workoutEngine
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.regular) {
                TextEditor(text: $notes)
                    .font(AppTheme.Typography.body)
                    .padding(AppTheme.Spacing.small)
                    .background(AppTheme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
            .padding(AppTheme.Spacing.regular)
            .navigationTitle("\(exercise.exerciseName) Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        workoutEngine.updateExerciseNotes(id: exercise.id, notes: notes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { notes = exercise.notes }
        }
    }
}
