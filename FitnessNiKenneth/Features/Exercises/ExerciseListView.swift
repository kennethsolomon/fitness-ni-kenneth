import SwiftUI
import SwiftData

struct ExerciseListView: View {

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedCategory: MovementCategory? = nil
    @State private var selectedEquipment: Equipment? = nil
    @State private var showCreateExercise = false
    @State private var showFilters = false

    var body: some View {
        Group {
            if exercises.isEmpty {
                EmptyStateView(
                    icon: "figure.strengthtraining.traditional",
                    title: "No Exercises",
                    subtitle: "Exercise library is loading..."
                )
            } else {
                exerciseList
            }
        }
        .navigationTitle("Exercises")
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }

                    Button {
                        showCreateExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateExercise) {
            NavigationStack {
                CreateExerciseView()
            }
        }
        .sheet(isPresented: $showFilters) {
            ExerciseFilterSheet(
                selectedCategory: $selectedCategory,
                selectedEquipment: $selectedEquipment
            )
        }
    }

    private var exerciseList: some View {
        List {
            if hasActiveFilter {
                Section {
                    filterChips
                }
            }

            ForEach(groupedExercises, id: \.0) { letter, group in
                Section(letter) {
                    ForEach(group) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseLibraryRow(exercise: exercise)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                if let category = selectedCategory {
                    FilterChip(label: category.displayName) {
                        selectedCategory = nil
                    }
                }
                if let equipment = selectedEquipment {
                    FilterChip(label: equipment.displayName) {
                        selectedEquipment = nil
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.small)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }

    private var groupedExercises: [(String, [Exercise])] {
        let filtered = filteredExercises
        let grouped = Dictionary(grouping: filtered) { exercise -> String in
            String(exercise.name.prefix(1)).uppercased()
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                exercise.primaryMuscleDisplayString.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil ||
                exercise.category == selectedCategory

            let matchesEquipment = selectedEquipment == nil ||
                exercise.equipment == selectedEquipment

            return matchesSearch && matchesCategory && matchesEquipment
        }
    }

    private var hasActiveFilter: Bool {
        selectedCategory != nil || selectedEquipment != nil
    }
}

// MARK: - ExerciseLibraryRow

struct ExerciseLibraryRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            Text(exercise.name)
                .font(AppTheme.Typography.body.weight(.medium))

            HStack(spacing: AppTheme.Spacing.small) {
                Text(exercise.primaryMuscleDisplayString)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary)

                Text("·")
                    .foregroundStyle(AppTheme.Colors.secondary)

                Text(exercise.equipment.displayName)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxSmall)
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxSmall) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.accent.opacity(0.15))
        .foregroundStyle(AppTheme.Colors.accent)
        .clipShape(Capsule())
    }
}

// MARK: - ExerciseFilterSheet

struct ExerciseFilterSheet: View {
    @Binding var selectedCategory: MovementCategory?
    @Binding var selectedEquipment: Equipment?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Movement Category") {
                    ForEach(MovementCategory.allCases, id: \.self) { category in
                        HStack {
                            Text(category.displayName)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }

                Section("Equipment") {
                    ForEach(Equipment.allCases, id: \.self) { equipment in
                        HStack {
                            Text(equipment.displayName)
                            Spacer()
                            if selectedEquipment == equipment {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEquipment = selectedEquipment == equipment ? nil : equipment
                        }
                    }
                }
            }
            .navigationTitle("Filter Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategory = nil
                        selectedEquipment = nil
                    }
                    .foregroundStyle(AppTheme.Colors.destructive)
                    .disabled(selectedCategory == nil && selectedEquipment == nil)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - CreateExerciseView

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedPrimaryMuscles: [MuscleGroup] = []
    @State private var selectedEquipment: Equipment = .barbell
    @State private var selectedCategory: MovementCategory = .push
    @State private var instructions = ""
    @State private var tips = ""
    @State private var commonMistakes = ""

    var body: some View {
        Form {
            Section("Name") {
                TextField("Exercise name", text: $name)
            }

            Section("Muscles (Primary)") {
                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    HStack {
                        Text(muscle.displayName)
                        Spacer()
                        if selectedPrimaryMuscles.contains(muscle) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let idx = selectedPrimaryMuscles.firstIndex(of: muscle) {
                            selectedPrimaryMuscles.remove(at: idx)
                        } else {
                            selectedPrimaryMuscles.append(muscle)
                        }
                    }
                }
            }

            Section("Equipment") {
                Picker("Equipment", selection: $selectedEquipment) {
                    ForEach(Equipment.allCases, id: \.self) { eq in
                        Text(eq.displayName).tag(eq)
                    }
                }
            }

            Section("Category") {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(MovementCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
            }

            Section("Instructions") {
                TextEditor(text: $instructions)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle("New Exercise")
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
    }

    private func save() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            primaryMuscles: selectedPrimaryMuscles,
            equipment: selectedEquipment,
            category: selectedCategory,
            instructions: instructions,
            tips: tips,
            commonMistakes: commonMistakes,
            isCustom: true
        )
        context.insert(exercise)
        try? context.save()
        dismiss()
    }
}
