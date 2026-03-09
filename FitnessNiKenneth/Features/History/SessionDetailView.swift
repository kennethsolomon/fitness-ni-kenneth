import SwiftUI
import SwiftData
import Charts

struct SessionDetailView: View {

    let session: WorkoutSession
    @Environment(\.modelContext) private var context
    @Query private var allSessions: [WorkoutSession]
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            headerSection
            exerciseSections
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete this workout?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: AppTheme.Spacing.xxLarge) {
                StatCell(
                    label: "Duration",
                    value: session.duration.shortDurationFormatted
                )
                Divider().frame(height: 40)
                StatCell(
                    label: "Sets",
                    value: "\(session.completedSetsCount)"
                )
                Divider().frame(height: 40)
                StatCell(
                    label: "Volume",
                    value: totalVolumeLabel
                )
            }
            .padding(.vertical, AppTheme.Spacing.small)

            if let finishedAt = session.finishedAt {
                LabeledContent("Date") {
                    Text(finishedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(AppTheme.Colors.secondary)
                }
            }

            LabeledContent("Duration") {
                Text(session.duration.workoutDurationFormatted)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }

            if !session.notes.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Notes")
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.secondary)
                    Text(session.notes)
                        .font(AppTheme.Typography.body)
                }
                .padding(.vertical, AppTheme.Spacing.xxSmall)
            }
        }
    }

    private var exerciseSections: some View {
        ForEach(session.sortedExercises) { workoutExercise in
            Section {
                ForEach(workoutExercise.sortedSets) { set in
                    SessionSetRow(set: set, setNumber: (workoutExercise.sortedSets.firstIndex(of: set) ?? 0) + 1)
                }
            } header: {
                HStack {
                    Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                    Spacer()
                    Text("\(workoutExercise.completedSets.count)/\(workoutExercise.sets.count) sets")
                        .foregroundStyle(AppTheme.Colors.secondary)
                }
                .font(AppTheme.Typography.subheadline)
            }
        }
    }

    private var totalVolumeLabel: String {
        let volume = session.totalVolume
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    private var prExerciseIDs: [UUID] {
        AnalyticsService.newPRs(in: session, comparedTo: allSessions)
    }
}

// MARK: - SessionSetRow

struct SessionSetRow: View {
    let set: WorkoutSet
    let setNumber: Int

    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(AppTheme.Typography.setNumber)
                .foregroundStyle(AppTheme.Colors.secondary)
                .frame(width: 24)

            Spacer()

            if set.isCompleted {
                if set.reps > 0 && set.weight > 0 {
                    Text("\(Int(set.weight)) \(set.unit.label) × \(set.reps)")
                        .font(AppTheme.Typography.body.weight(.medium))
                } else if set.reps > 0 {
                    Text("\(set.reps) reps")
                        .font(AppTheme.Typography.body.weight(.medium))
                } else {
                    Text("–")
                        .foregroundStyle(AppTheme.Colors.secondary)
                }

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.Colors.completedSet)
            } else {
                Text("Skipped")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxSmall)
    }
}
