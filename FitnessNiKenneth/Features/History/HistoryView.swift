import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var showCalendar = false

    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.xmark",
                    title: "No Workouts Yet",
                    subtitle: "Finish your first workout and it will appear here."
                )
            } else {
                List {
                    if !sessions.isEmpty {
                        Section {
                            summaryRow
                        }
                    }

                    ForEach(groupedSessions, id: \.0) { monthKey, monthSessions in
                        Section(monthKey) {
                            ForEach(monthSessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    SessionRow(session: session)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCalendar = true
                } label: {
                    Image(systemName: "calendar")
                }
            }
        }
        .sheet(isPresented: $showCalendar) {
            NavigationStack {
                WorkoutCalendarView(sessions: sessions)
                    .navigationTitle("Calendar")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showCalendar = false }
                        }
                    }
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: AppTheme.Spacing.xxLarge) {
            StatCell(
                label: "Total",
                value: "\(sessions.count)",
                subtitle: "workouts"
            )
            Divider().frame(height: 40)
            StatCell(
                label: "This Week",
                value: "\(thisWeekCount)",
                subtitle: "workouts"
            )
            Divider().frame(height: 40)
            StatCell(
                label: "Best Streak",
                value: "\(bestStreak)",
                subtitle: "days"
            )
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }

    private var groupedSessions: [(String, [WorkoutSession])] {
        let grouped = Dictionary(grouping: sessions) { session -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: session.startedAt)
        }
        return grouped
            .sorted { lhs, rhs in
                guard let lhsDate = parseMonthKey(lhs.key),
                      let rhsDate = parseMonthKey(rhs.key) else { return false }
                return lhsDate > rhsDate
            }
            .map { ($0.key, $0.value.sorted { $0.startedAt > $1.startedAt }) }
    }

    private func parseMonthKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.date(from: key)
    }

    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return sessions.filter { $0.startedAt >= startOfWeek }.count
    }

    private var bestStreak: Int {
        let dates = sessions
            .compactMap { $0.finishedAt }
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted(by: >)

        var streak = 0
        var maxStreak = 0
        var previousDate: Date?

        for date in dates {
            if let prev = previousDate {
                let diff = Calendar.current.dateComponents([.day], from: date, to: prev).day ?? 0
                if diff == 1 {
                    streak += 1
                } else {
                    streak = 1
                }
            } else {
                streak = 1
            }
            maxStreak = max(maxStreak, streak)
            previousDate = date
        }
        return maxStreak
    }
}

// MARK: - SessionRow

struct SessionRow: View {

    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            HStack {
                Text(session.name)
                    .font(AppTheme.Typography.headline)

                Spacer()

                Text(session.duration.shortDurationFormatted)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }

            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondary)

            if !session.exercises.isEmpty {
                Text(session.sortedExercises.compactMap { $0.exercise?.name }.prefix(3).joined(separator: " · "))
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: AppTheme.Spacing.regular) {
                Label("\(session.completedSetsCount) sets", systemImage: "repeat")
                if session.totalVolume > 0 {
                    Label(volumeLabel, systemImage: "scalemass")
                }
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.Colors.secondary)
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }

    private var volumeLabel: String {
        let volume = session.totalVolume
        if volume >= 1000 {
            return String(format: "%.1fk lbs", volume / 1000)
        } else {
            return String(format: "%.0f lbs", volume)
        }
    }
}
