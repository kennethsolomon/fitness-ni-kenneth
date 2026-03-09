import SwiftUI
import SwiftData

struct EditTemplateView: View {

    let template: WorkoutTemplate?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var exercises: [EditableTemplateExercise] = []
    @State private var showExercisePicker = false

    var isEditing: Bool { template != nil }

    var body: some View {
        Form {
            Section("Template Name") {
                TextField("e.g. Push Day", text: $name)
            }

            Section {
                ForEach(exercises) { exercise in
                    EditableTemplateExerciseRow(exercise: binding(for: exercise))
                }
                .onDelete { indexSet in
                    exercises.remove(atOffsets: indexSet)
                }
                .onMove { from, to in
                    exercises.move(fromOffsets: from, toOffset: to)
                }

                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            } header: {
                HStack {
                    Text("Exercises")
                    Spacer()
                    EditButton()
                        .font(AppTheme.Typography.footnote)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear { loadExistingTemplate() }
        .sheet(isPresented: $showExercisePicker) {
            NavigationStack {
                ExercisePickerView(excludedIDs: exercises.map(\.exerciseID)) { exercise in
                    addExercise(exercise)
                }
            }
        }
    }

    private func binding(for exercise: EditableTemplateExercise) -> Binding<EditableTemplateExercise> {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else {
            return .constant(exercise)
        }
        return $exercises[index]
    }

    private func loadExistingTemplate() {
        guard let template else { return }
        name = template.name
        exercises = template.sortedExercises.map { te in
            EditableTemplateExercise(
                id: te.id,
                exerciseID: te.exercise?.id ?? UUID(),
                exerciseName: te.exercise?.name ?? "",
                defaultSets: te.defaultSets,
                defaultReps: te.defaultReps,
                defaultWeight: te.defaultWeight,
                defaultUnit: te.defaultUnit,
                restSeconds: te.restSeconds
            )
        }
    }

    private func addExercise(_ exercise: Exercise) {
        exercises.append(EditableTemplateExercise(
            exerciseID: exercise.id,
            exerciseName: exercise.name
        ))
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else { return }

        if let existing = template {
            existing.name = cleanName
            for te in existing.exercises {
                context.delete(te)
            }
            existing.exercises = makeTemplateExercises(for: existing)
        } else {
            let newTemplate = WorkoutTemplate(name: cleanName)
            context.insert(newTemplate)
            newTemplate.exercises = makeTemplateExercises(for: newTemplate)
        }

        try? context.save()
        dismiss()
    }

    private func makeTemplateExercises(for template: WorkoutTemplate) -> [TemplateExercise] {
        exercises.enumerated().compactMap { index, editableExercise -> TemplateExercise? in
            let exerciseID = editableExercise.exerciseID
            var descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.id == exerciseID }
            )
            descriptor.fetchLimit = 1
            guard let exercise = try? context.fetch(descriptor).first else { return nil }
            let te = TemplateExercise(
                exercise: exercise,
                order: index,
                defaultSets: editableExercise.defaultSets,
                defaultReps: editableExercise.defaultReps,
                defaultWeight: editableExercise.defaultWeight,
                defaultUnit: editableExercise.defaultUnit,
                restSeconds: editableExercise.restSeconds
            )
            te.template = template
            context.insert(te)
            return te
        }
    }
}

// MARK: - EditableTemplateExercise

struct EditableTemplateExercise: Identifiable {
    var id: UUID
    var exerciseID: UUID
    var exerciseName: String
    var defaultSets: Int
    var defaultReps: Int
    var defaultWeight: Double
    var defaultUnit: WeightUnit
    var restSeconds: Int

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        exerciseName: String,
        defaultSets: Int = 3,
        defaultReps: Int = 10,
        defaultWeight: Double = 0,
        defaultUnit: WeightUnit = .lbs,
        restSeconds: Int = 90
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.defaultUnit = defaultUnit
        self.restSeconds = restSeconds
    }
}

// MARK: - EditableTemplateExerciseRow

struct EditableTemplateExerciseRow: View {
    @Binding var exercise: EditableTemplateExercise

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(exercise.exerciseName)
                .font(AppTheme.Typography.body.weight(.medium))

            HStack(spacing: AppTheme.Spacing.large) {
                Stepper("Sets: \(exercise.defaultSets)", value: $exercise.defaultSets, in: 1...20)
                    .font(AppTheme.Typography.subheadline)

                Stepper("Reps: \(exercise.defaultReps)", value: $exercise.defaultReps, in: 1...100)
                    .font(AppTheme.Typography.subheadline)
            }

            HStack {
                Text("Rest:")
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary)
                Picker("Rest", selection: $exercise.restSeconds) {
                    ForEach(restOptions, id: \.self) { seconds in
                        Text(seconds.restTimerFormatted).tag(seconds)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }

    private let restOptions = [30, 60, 90, 120, 180, 240, 300]
}

// MARK: - ExercisePickerView (for templates)

struct ExercisePickerView: View {
    let excludedIDs: [UUID]
    let onSelect: (Exercise) -> Void

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: MovementCategory? = nil
    @State private var selectedEquipment: Equipment? = nil

    var body: some View {
        List(filteredExercises) { exercise in
            Button {
                onSelect(exercise)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                    Text(exercise.name)
                        .font(AppTheme.Typography.body.weight(.medium))
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text(exercise.primaryMuscleDisplayString)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.secondary)
                }
                .padding(.vertical, AppTheme.Spacing.xxSmall)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search exercises")
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            guard !excludedIDs.contains(exercise.id) else { return false }
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesSearch
        }
    }
}
