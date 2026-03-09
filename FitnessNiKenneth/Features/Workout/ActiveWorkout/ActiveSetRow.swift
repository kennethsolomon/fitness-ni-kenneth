import SwiftUI

struct ActiveSetRow: View {

    let set: ActiveSet
    let setNumber: Int
    let exerciseID: UUID
    let previousPerformance: WorkoutSetSnapshot?
    let isPR: Bool

    @Environment(WorkoutEngine.self) private var workoutEngine

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            // Set number
            Text("\(setNumber)")
                .font(AppTheme.Typography.setNumber)
                .foregroundStyle(set.isCompleted ? AppTheme.Colors.completedSet : AppTheme.Colors.secondary)
                .frame(width: 36, alignment: .center)

            // Previous
            if let prev = previousPerformance {
                Text(prev.weight > 0 ? "\(Int(prev.weight)) × \(prev.reps)" : "\(prev.reps) reps")
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
            } else {
                Text("–")
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // Weight input
            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(AppTheme.Typography.weightInput)
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
            }
            .frame(width: 72)

            // Reps input
            HStack(spacing: 4) {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(AppTheme.Typography.weightInput)
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

    private func syncFields() {
        if set.weight > 0 {
            weightText = set.weight == set.weight.rounded() ? "\(Int(set.weight))" : String(format: "%.1f", set.weight)
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
