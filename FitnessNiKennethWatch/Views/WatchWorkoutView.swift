import SwiftUI

// MARK: - WatchRootView

struct WatchRootView: View {
    @Environment(WatchWorkoutEngine.self) private var engine

    var body: some View {
        if engine.isActive {
            WatchActiveWorkoutView()
        } else {
            WatchIdleView()
        }
    }
}

// MARK: - WatchIdleView

struct WatchIdleView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.accentColor)
            Text("Open the app\non your iPhone\nto start a workout")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - WatchActiveWorkoutView

struct WatchActiveWorkoutView: View {
    @Environment(WatchWorkoutEngine.self) private var engine

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Workout name
                Text(engine.workoutName)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Divider()

                // Elapsed time
                VStack(spacing: 2) {
                    Text("Elapsed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(engine.elapsedSeconds.watchTimerFormatted)
                        .font(.system(size: 28, weight: .thin, design: .monospaced))
                        .foregroundStyle(Color.accentColor)
                }

                // Rest timer
                if engine.isResting && engine.restSecondsRemaining > 0 {
                    WatchRestTimerView()
                } else if !engine.currentExercise.isEmpty {
                    // Current exercise
                    VStack(spacing: 4) {
                        Text(engine.currentExercise)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if engine.totalSets > 0 {
                            Text("Set \(engine.currentSet) of \(engine.totalSets)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - WatchRestTimerView

struct WatchRestTimerView: View {
    @Environment(WatchWorkoutEngine.self) private var engine

    var body: some View {
        VStack(spacing: 4) {
            Text("Rest")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(engine.restSecondsRemaining.watchTimerFormatted)
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Int extension for Watch

extension Int {
    var watchTimerFormatted: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
