import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {

    let exercise: Exercise
    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var allSessions: [WorkoutSession]
    @Environment(WorkoutEngine.self) private var workoutEngine
    @State private var selectedTab = 0

    private var stats: (bestSet: WorkoutSetSnapshot?, oneRM: Double, totalSessions: Int, maxReps: Int) {
        let bestSet = AnalyticsService.bestSet(for: exercise.id, in: allSessions)
        let oneRM = bestSet.map { AnalyticsFormulas.epleyOneRepMax(weight: $0.weight, reps: $0.reps) } ?? 0
        let totalSessions = AnalyticsService.sessionCount(for: exercise.id, in: allSessions)
        let maxReps = AnalyticsService.maxReps(for: exercise.id, in: allSessions)
        return (bestSet, oneRM, totalSessions, maxReps)
    }

    var body: some View {
        List {
            // Stats header
            if stats.totalSessions > 0 {
                Section {
                    statsHeader
                }
            }

            // Overview / Instructions
            Section("How to Perform") {
                if !exercise.instructions.isEmpty {
                    Text(exercise.instructions)
                        .font(AppTheme.Typography.body)
                        .lineSpacing(4)
                }
            }

            if !exercise.tips.isEmpty {
                Section("Tips") {
                    Text(exercise.tips)
                        .font(AppTheme.Typography.body)
                        .lineSpacing(4)
                }
            }

            if !exercise.commonMistakes.isEmpty {
                Section("Common Mistakes") {
                    Text(exercise.commonMistakes)
                        .font(AppTheme.Typography.body)
                        .lineSpacing(4)
                }
            }

            // Muscles
            Section("Muscles") {
                musclesSection
            }

            // Charts
            let oneRMHistory = AnalyticsService.oneRMHistory(for: exercise.id, in: allSessions)
            let volumeHistory = AnalyticsService.volumeHistory(for: exercise.id, in: allSessions)

            if !oneRMHistory.isEmpty {
                Section("Estimated 1RM Progress") {
                    OneRMChart(dataPoints: oneRMHistory)
                        .frame(height: 180)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }

            if !volumeHistory.isEmpty {
                Section("Volume per Session") {
                    VolumeChart(dataPoints: volumeHistory)
                        .frame(height: 180)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }

            // History
            let exerciseSessions = sessionsContainingExercise
            if !exerciseSessions.isEmpty {
                Section("History") {
                    ForEach(exerciseSessions.prefix(20)) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            ExerciseSessionRow(session: session, exerciseID: exercise.id)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    workoutEngine.addExercise(
                        exerciseID: exercise.id,
                        exerciseName: exercise.name
                    )
                } label: {
                    Label("Add to Workout", systemImage: "plus.circle")
                }
                .disabled(!workoutEngine.isActive)
            }
        }
    }

    private var statsHeader: some View {
        HStack(spacing: 0) {
            StatCell(
                label: "Sessions",
                value: "\(stats.totalSessions)"
            )
            Divider().frame(height: 40).padding(.horizontal, AppTheme.Spacing.large)
            if let best = stats.bestSet {
                StatCell(
                    label: "Best Set",
                    value: "\(Int(best.weight)) \(best.unit.label)",
                    subtitle: "\(best.reps) reps"
                )
            }
            Divider().frame(height: 40).padding(.horizontal, AppTheme.Spacing.large)
            StatCell(
                label: "Est. 1RM",
                value: stats.oneRM > 0 ? "\(stats.oneRM.oneRMFormatted)" : "–",
                subtitle: stats.oneRM > 0 ? "lbs" : nil
            )
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }

    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if !exercise.primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Primary")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.xSmall) {
                            ForEach(exercise.primaryMuscles, id: \.rawValue) { muscle in
                                MuscleGroupTag(muscle: muscle, isPrimary: true)
                            }
                        }
                    }
                }
            }

            if !exercise.secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Secondary")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.xSmall) {
                            ForEach(exercise.secondaryMuscles, id: \.rawValue) { muscle in
                                MuscleGroupTag(muscle: muscle, isPrimary: false)
                            }
                        }
                    }
                }
            }

            HStack {
                Image(systemName: exerciseIcon)
                    .foregroundStyle(AppTheme.Colors.accent)
                Text(exercise.equipment.displayName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondary)
                Spacer()
                Text(exercise.category.displayName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }
        }
    }

    private var sessionsContainingExercise: [WorkoutSession] {
        allSessions.filter { session in
            session.exercises.contains { $0.exercise?.id == exercise.id }
        }
    }

    private var exerciseIcon: String {
        switch exercise.equipment {
        case .barbell: "scalemass.fill"
        case .dumbbell: "dumbbell.fill"
        case .bodyweight: "figure.walk"
        case .cable: "cable.connector"
        case .machine: "gearshape.fill"
        default: "dumbbell"
        }
    }
}

// MARK: - ExerciseSessionRow

struct ExerciseSessionRow: View {
    let session: WorkoutSession
    let exerciseID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            HStack {
                Text(session.name)
                    .font(AppTheme.Typography.subheadline.weight(.medium))
                Spacer()
                Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }
            if let workoutExercise = session.exercises.first(where: { $0.exercise?.id == exerciseID }) {
                let completed = workoutExercise.completedSets
                if let best = completed.max(by: { $0.volume < $1.volume }) {
                    Text("Best: \(Int(best.weight)) \(best.unit.label) × \(best.reps)")
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.secondary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxSmall)
    }
}

// MARK: - OneRMChart

struct OneRMChart: View {
    let dataPoints: [OneRMDataPoint]

    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("1RM", point.oneRM)
            )
            .foregroundStyle(AppTheme.Colors.accent)
            .interpolationMethod(.monotone)

            AreaMark(
                x: .value("Date", point.date),
                y: .value("1RM", point.oneRM)
            )
            .foregroundStyle(AppTheme.Colors.accent.opacity(0.1))
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Date", point.date),
                y: .value("1RM", point.oneRM)
            )
            .foregroundStyle(AppTheme.Colors.accent)
            .symbolSize(30)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
    }
}

// MARK: - VolumeChart

struct VolumeChart: View {
    let dataPoints: [VolumeDataPoint]

    var body: some View {
        Chart(dataPoints) { point in
            BarMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.volume)
            )
            .foregroundStyle(AppTheme.Colors.accent.gradient)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
    }
}
