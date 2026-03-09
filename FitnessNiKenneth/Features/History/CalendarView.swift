import SwiftUI

struct WorkoutCalendarView: View {

    let sessions: [WorkoutSession]
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            monthNavigationHeader

            Divider()

            dayOfWeekHeader

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(calendarDays, id: \.self) { date in
                    DayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        isToday: isToday(date),
                        workoutCount: workoutCount(for: date)
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.small)

            Divider()

            sessionListForMonth
        }
    }

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                advanceMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.medium))
            }
            .padding()

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(AppTheme.Typography.title3)
                .fontWeight(.semibold)

            Spacer()

            Button {
                advanceMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.medium))
            }
            .padding()
        }
    }

    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.small)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    private var sessionListForMonth: some View {
        let monthSessions = sessions.filter { isCurrentMonth($0.startedAt) }.sorted { $0.startedAt > $1.startedAt }

        return List(monthSessions) { session in
            NavigationLink {
                SessionDetailView(session: session)
            } label: {
                SessionRow(session: session)
            }
        }
        .listStyle(.plain)
        .overlay {
            if monthSessions.isEmpty {
                Text("No workouts this month")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var calendarDays: [Date] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }

        let startWeekday = calendar.component(.weekday, from: monthStart) - 1
        let totalDays = calendar.component(.day, from: monthEnd)

        var days: [Date] = []

        for offset in 0..<startWeekday {
            let date = calendar.date(byAdding: .day, value: -(startWeekday - offset), to: monthStart)!
            days.append(date)
        }

        for day in 1...totalDays {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            days.append(date)
        }

        let remainingCells = (7 - (days.count % 7)) % 7
        for offset in 1...max(1, remainingCells) {
            let date = calendar.date(byAdding: .day, value: offset, to: monthEnd)!
            days.append(date)
        }

        return days
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func workoutCount(for date: Date) -> Int {
        sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: date) }.count
    }

    private func advanceMonth(by months: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: months, to: displayedMonth) ?? displayedMonth
    }
}

// MARK: - DayCell

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let workoutCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 30, height: 30)
                    }

                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(AppTheme.Typography.footnote.weight(isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? .white : isCurrentMonth ? AppTheme.Colors.primary : AppTheme.Colors.secondary.opacity(0.4))
                        .frame(width: 30, height: 30)
                }

                if workoutCount > 0 && isCurrentMonth {
                    HStack(spacing: 2) {
                        ForEach(0..<min(workoutCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .frame(width: 5, height: 5)
                        }
                    }
                } else {
                    Color.clear.frame(height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xSmall)
        }
    }
}
