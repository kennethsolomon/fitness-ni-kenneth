import SwiftUI

struct TimerToolbarButton: View {

    @Environment(WorkoutEngine.self) private var workoutEngine
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            if workoutEngine.isResting {
                activeLabel
            } else {
                idleLabel
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: workoutEngine.isResting)
    }

    private var idleLabel: some View {
        Image(systemName: "timer")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(AppTheme.Colors.heavyPurple)
            .frame(width: 36, height: 36)
            .background(AppTheme.Colors.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var activeLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .bold))
            Text(workoutEngine.restSecondsRemaining.restTimerFormatted)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
        }
        .foregroundStyle(AppTheme.Colors.background)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(AppTheme.Colors.iceCold)
        .clipShape(Capsule())
    }
}
