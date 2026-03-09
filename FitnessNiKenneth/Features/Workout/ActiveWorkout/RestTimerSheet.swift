import SwiftUI

struct RestTimerSheet: View {

    @Environment(WorkoutEngine.self) private var workoutEngine
    @Environment(\.dismiss) private var dismiss

    @State private var showCustomPicker = false
    @State private var customMinutes = 1
    @State private var customSeconds = 30

    private let presets = [30, 60, 120, 180]

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.tertiaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Rest Timer")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                .padding(.horizontal, AppTheme.Spacing.regular)
                .padding(.top, AppTheme.Spacing.regular)
                .padding(.bottom, AppTheme.Spacing.medium)

                if showCustomPicker {
                    customPickerContent
                } else if workoutEngine.isResting {
                    countdownContent
                } else {
                    presetPickerContent
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Preset Picker

    private var presetPickerContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Text("Choose a duration below or set your own.\nCustom durations are saved for next time.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.regular)

            // Decorative ring with preset list inside
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.iceCold, lineWidth: 3)
                    .padding(AppTheme.Spacing.regular)

                VStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(presets, id: \.self) { seconds in
                        Button {
                            workoutEngine.startRestTimer(seconds: seconds)
                            dismiss()
                        } label: {
                            Text(seconds.restTimerFormatted)
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.small)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 60)
            }
            .frame(height: 280)

            Button {
                showCustomPicker = true
            } label: {
                Text("Create Custom Timer")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.iceCold)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.regular)
                    .background(AppTheme.Colors.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.regular)
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.97)),
            removal: .opacity
        ))
    }

    // MARK: - Active Countdown

    private var countdownContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Text("Adjust duration via the +/− buttons.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondary)
                .padding(.horizontal, AppTheme.Spacing.regular)

            // Progress ring
            ZStack {
                // Track
                Circle()
                    .stroke(AppTheme.Colors.tertiaryBackground, lineWidth: 6)
                    .padding(AppTheme.Spacing.regular)

                // Progress arc
                let progress = workoutEngine.restTotalSeconds > 0
                    ? Double(workoutEngine.restSecondsRemaining) / Double(max(1, workoutEngine.restTotalSeconds))
                    : 0

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppTheme.Colors.iceCold,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(AppTheme.Spacing.regular)
                    .animation(.linear(duration: 1.0), value: progress)

                // Time labels
                VStack(spacing: 4) {
                    Text(workoutEngine.restSecondsRemaining.restTimerFormatted)
                        .font(AppTheme.Typography.timerCountdown)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))

                    Text(workoutEngine.restTotalSeconds.restTimerFormatted)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondary)
                        .monospacedDigit()
                }
            }
            .frame(height: 240)

            // Controls
            HStack(spacing: AppTheme.Spacing.small) {
                Button {
                    workoutEngine.adjustRestTimer(by: -10)
                } label: {
                    Text("−10s")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.medium)
                        .background(AppTheme.Colors.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                .buttonStyle(.plain)

                Button {
                    workoutEngine.adjustRestTimer(by: 10)
                } label: {
                    Text("+10s")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.medium)
                        .background(AppTheme.Colors.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                .buttonStyle(.plain)

                Button {
                    workoutEngine.cancelRestTimer()
                    dismiss()
                } label: {
                    Text("Skip")
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.medium)
                        .background(AppTheme.Colors.purplePain)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Spacing.regular)
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.97)),
            removal: .opacity
        ))
    }

    // MARK: - Custom Picker

    private var customPickerContent: some View {
        VStack(spacing: AppTheme.Spacing.xLarge) {
            Text("Set a custom duration.")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondary)
                .padding(.horizontal, AppTheme.Spacing.regular)

            HStack(spacing: 0) {
                Picker("Minutes", selection: $customMinutes) {
                    ForEach(0..<60, id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("Seconds", selection: $customSeconds) {
                    ForEach(0..<60, id: \.self) { s in
                        Text("\(s) sec").tag(s)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(AppTheme.Colors.primary)

            Button {
                let total = customMinutes * 60 + customSeconds
                guard total > 0 else { return }
                workoutEngine.startRestTimer(seconds: total)
                showCustomPicker = false
                dismiss()
            } label: {
                Text("Start Timer")
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.regular)
                    .background(AppTheme.Colors.purplePain)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.regular)
            .padding(.bottom, AppTheme.Spacing.large)
        }
    }
}
