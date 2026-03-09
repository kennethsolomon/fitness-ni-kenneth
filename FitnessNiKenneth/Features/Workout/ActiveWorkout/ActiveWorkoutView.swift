import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {

    @Environment(WorkoutEngine.self) private var workoutEngine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var allSessions: [WorkoutSession]

    @State private var showCancelConfirm = false
    @State private var showFinishSheet = false
    @State private var showExercisePicker = false
    @State private var showSessionNotes = false
    @State private var showRestTimerSheet = false
    @State private var sessionNotesDraft = ""

    var body: some View {
        NavigationStack {
            Group {
                if let session = workoutEngine.session {
                    workoutContent(session: session)
                } else {
                    Text("No active workout")
                        .foregroundStyle(AppTheme.Colors.secondary)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .foregroundStyle(AppTheme.Colors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func workoutContent(session: ActiveSession) -> some View {
        ZStack(alignment: .bottom) {
            AppTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    timerBanner(session: session)

                    LazyVStack(spacing: AppTheme.Spacing.medium, pinnedViews: []) {
                        ForEach(session.exercises) { exercise in
                            ActiveExerciseSection(
                                exercise: exercise,
                                allSessions: allSessions
                            )
                            .padding(.horizontal, AppTheme.Spacing.regular)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.medium)
                    .padding(.bottom, 140)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            bottomBar
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                TimerToolbarButton {
                    showRestTimerSheet = true
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Finish") {
                    showFinishSheet = true
                }
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.Colors.success)
                .clipShape(Capsule())
            }
        }
        .sheet(isPresented: $showRestTimerSheet) {
            RestTimerSheet()
                .environment(workoutEngine)
        }
        .sheet(isPresented: $showExercisePicker) {
            NavigationStack {
                ExercisePickerView(excludedIDs: session.exercises.map(\.exerciseID)) { exercise in
                    workoutEngine.addExercise(
                        exerciseID: exercise.id,
                        exerciseName: exercise.name
                    )
                }
            }
        }
        .sheet(isPresented: $showFinishSheet) {
            NavigationStack {
                FinishWorkoutView(session: session)
            }
        }
        .sheet(isPresented: $showSessionNotes) {
            SessionNotesSheet(notes: $sessionNotesDraft) {
                workoutEngine.updateSessionNotes(sessionNotesDraft)
            }
        }
        .confirmationDialog(
            "Cancel Workout?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Cancel Workout", role: .destructive) {
                workoutEngine.cancelWorkout()
                dismiss()
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will not be saved.")
        }
    }

    private func timerBanner(session: ActiveSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Elapsed")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(workoutEngine.elapsedSeconds.workoutTimerFormatted)
                    .font(AppTheme.Typography.timerSmall)
                    .foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Started")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(session.startedAt.formatted(date: .omitted, time: .shortened))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.regular)
        .padding(.vertical, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.purplePain.gradient)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppTheme.Colors.separator)
            HStack {
                Button {
                    showExercisePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Exercise")
                            .font(AppTheme.Typography.headline)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.Colors.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.regular)
            .background(AppTheme.Colors.background.opacity(0.95))

            Divider()
                .background(AppTheme.Colors.separator)

            Button(role: .destructive) {
                showCancelConfirm = true
            } label: {
                Text("Cancel Workout")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.destructive)
            }
            .padding(.vertical, AppTheme.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.background.opacity(0.95))
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - SessionNotesSheet

struct SessionNotesSheet: View {
    @Binding var notes: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.regular) {
            TextEditor(text: $notes)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primary)
                .padding(AppTheme.Spacing.small)
                .background(AppTheme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .padding(AppTheme.Spacing.regular)
        .background(AppTheme.Colors.background)
        .navigationTitle("Workout Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .preferredColorScheme(.dark)
    }
}
