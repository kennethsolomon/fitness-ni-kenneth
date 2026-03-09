import SwiftUI

// MARK: - SetBadgeView

struct SetBadgeView: View {
    let set: ActiveSet
    let setNumber: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(badgeBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(badgeBorder, lineWidth: 1)
                )

            Text(badgeText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(badgeForeground)
        }
        .frame(width: 28, height: 28)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: set.tag)
    }

    private var badgeText: String {
        let tag = set.tag
        return tag == .normal ? "\(setNumber)" : tag.badgeLabel
    }

    private var badgeBackground: Color {
        switch set.tag {
        case .normal:  AppTheme.Colors.tertiaryBackground
        case .warmup:  AppTheme.Colors.warmupBadge.opacity(0.2)
        case .dropSet: AppTheme.Colors.dropSetBadge.opacity(0.2)
        case .failure: AppTheme.Colors.failureBadge.opacity(0.3)
        }
    }

    private var badgeForeground: Color {
        switch set.tag {
        case .normal:  AppTheme.Colors.primary
        case .warmup:  AppTheme.Colors.warmupBadge
        case .dropSet: AppTheme.Colors.dropSetBadge
        case .failure: AppTheme.Colors.failureBadge
        }
    }

    private var badgeBorder: Color {
        switch set.tag {
        case .normal:  Color.clear
        case .warmup:  AppTheme.Colors.warmupBadge.opacity(0.4)
        case .dropSet: AppTheme.Colors.dropSetBadge.opacity(0.4)
        case .failure: AppTheme.Colors.failureBadge.opacity(0.5)
        }
    }
}

// MARK: - ActiveSetRow

struct ActiveSetRow: View {

    let set: ActiveSet
    let setNumber: Int
    let exerciseID: UUID
    let previousPerformance: WorkoutSetSnapshot?
    let isPR: Bool

    @Environment(WorkoutEngine.self) private var workoutEngine

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var showTagMenu = false
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            // Set badge — tap to change tag
            Button {
                showTagMenu = true
            } label: {
                SetBadgeView(set: set, setNumber: setNumber)
            }
            .buttonStyle(.plain)
            .confirmationDialog("Set Type", isPresented: $showTagMenu, titleVisibility: .visible) {
                Button("Normal") {
                    workoutEngine.updateSetTag(setID: set.id, exerciseID: exerciseID, tag: .normal)
                }
                Button("Warm-up") {
                    workoutEngine.updateSetTag(setID: set.id, exerciseID: exerciseID, tag: .warmup)
                }
                Button("Drop Set") {
                    workoutEngine.updateSetTag(setID: set.id, exerciseID: exerciseID, tag: .dropSet)
                }
                Button("Failure", role: .destructive) {
                    workoutEngine.updateSetTag(setID: set.id, exerciseID: exerciseID, tag: .failure)
                }
                Button("Cancel", role: .cancel) {}
            }

            // Previous
            if let prev = previousPerformance {
                Text(previousText(prev))
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("–")
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // Weight input
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(AppTheme.Typography.weightInput)
                .foregroundStyle(AppTheme.Colors.primary)
                .focused($weightFocused)
                .frame(width: 52)
                .padding(.vertical, 6)
                .background(
                    set.isCompleted
                        ? AppTheme.Colors.completedSet.opacity(0.12)
                        : AppTheme.Colors.tertiaryBackground
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .onChange(of: weightFocused) { _, focused in
                    if !focused { commitEdit() }
                }
                .frame(width: 72)

            // Reps input
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(AppTheme.Typography.weightInput)
                .foregroundStyle(AppTheme.Colors.primary)
                .focused($repsFocused)
                .frame(width: 44)
                .padding(.vertical, 6)
                .background(
                    set.isCompleted
                        ? AppTheme.Colors.completedSet.opacity(0.12)
                        : AppTheme.Colors.tertiaryBackground
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .onChange(of: repsFocused) { _, focused in
                    if !focused { commitEdit() }
                }
                .frame(width: 60)

            // Complete button + PR badge
            ZStack(alignment: .topTrailing) {
                CompletionCheckmark(isCompleted: set.isCompleted) {
                    commitEdit()
                    withAnimation(AppTheme.Animation.spring) {
                        workoutEngine.toggleSetCompletion(setID: set.id, exerciseID: exerciseID)
                    }
                }
                .frame(width: 36)

                if isPR && set.isCompleted {
                    PRBadge()
                        .offset(x: 8, y: -8)
                }
            }
            .frame(width: 36)
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .contentShape(Rectangle())
        .background(set.isCompleted ? AppTheme.Colors.completedSet.opacity(0.06) : Color.clear)
        .animation(AppTheme.Animation.standard, value: set.isCompleted)
        .onAppear { syncFields() }
        .onChange(of: set.weight) { _, _ in syncFields() }
        .onChange(of: set.reps) { _, _ in syncFields() }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(AppTheme.Animation.spring) {
                    workoutEngine.removeSet(setID: set.id, from: exerciseID)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func previousText(_ prev: WorkoutSetSnapshot) -> String {
        var base = prev.weight > 0
            ? "\(Int(prev.weight)) \(prev.unit.label) × \(prev.reps)"
            : "\(prev.reps) reps"
        if prev.tag != .normal {
            base += " (\(prev.tag.badgeLabel))"
        }
        return base
    }

    private func syncFields() {
        if set.weight > 0 {
            weightText = set.weight == set.weight.rounded()
                ? "\(Int(set.weight))"
                : String(format: "%.1f", set.weight)
        } else {
            weightText = ""
        }
        repsText = set.reps > 0 ? "\(set.reps)" : ""
    }

    private func commitEdit() {
        let weight = Double(weightText) ?? 0
        let reps = Int(repsText) ?? 0
        workoutEngine.updateSet(
            setID: set.id,
            exerciseID: exerciseID,
            weight: weight,
            reps: reps,
            unit: set.unit
        )
    }
}
