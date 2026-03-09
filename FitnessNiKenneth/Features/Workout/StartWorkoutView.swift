import SwiftUI
import SwiftData

struct StartWorkoutView: View {

    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]

    @Environment(WorkoutEngine.self) private var workoutEngine
    @Environment(\.modelContext) private var context

    @State private var showCreateTemplate = false
    @State private var showEmptyWorkoutConfirm = false
    @State private var showActiveWorkout = false
    @State private var templateToDelete: WorkoutTemplate?

    var body: some View {
        List {
            startSection
            templatesSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Workout")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateTemplate) {
            NavigationStack {
                EditTemplateView(template: nil)
            }
        }
        .sheet(isPresented: $showActiveWorkout) {
            ActiveWorkoutView()
        }
        .confirmationDialog(
            "Start empty workout?",
            isPresented: $showEmptyWorkoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Start Workout") {
                workoutEngine.startEmptyWorkout()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Template?", isPresented: .constant(templateToDelete != nil)) {
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    context.delete(template)
                    try? context.save()
                }
                templateToDelete = nil
            }
            Button("Cancel", role: .cancel) { templateToDelete = nil }
        } message: {
            Text("This will permanently delete the template. Your workout history is not affected.")
        }
    }

    private var startSection: some View {
        Section {
            if workoutEngine.isActive {
                // Continue active session
                Button {
                    showActiveWorkout = true
                } label: {
                    HStack {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.Colors.iceCold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continue Workout")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.primary)
                            if let name = workoutEngine.session?.name {
                                Text("\(name) · \(workoutEngine.elapsedSeconds.workoutTimerFormatted)")
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundStyle(AppTheme.Colors.iceCold)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.secondary)
                    }
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                }
            } else {
                // Start new session
                Button {
                    showEmptyWorkoutConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.Colors.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Empty Workout")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.primary)
                            Text("Build your workout as you go")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                }
            }
        }
    }

    private var templatesSection: some View {
        Section {
            if templates.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Templates Yet",
                    subtitle: "Create a template to quickly start your regular workouts.",
                    actionTitle: "Create Template"
                ) {
                    showCreateTemplate = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.large)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                ForEach(templates) { template in
                    NavigationLink {
                        TemplateDetailView(template: template)
                    } label: {
                        TemplateRow(template: template)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            templateToDelete = template
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        NavigationLink {
                            EditTemplateView(template: template)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        } header: {
            Text("Templates")
        }
    }
}

// MARK: - TemplateRow

struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(template.name)
                .font(AppTheme.Typography.headline)

            HStack(spacing: AppTheme.Spacing.regular) {
                Label("\(template.exercises.count) exercises", systemImage: "dumbbell")
                if let lastUsed = template.lastUsedAt {
                    Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "clock")
                }
            }
            .font(AppTheme.Typography.footnote)
            .foregroundStyle(AppTheme.Colors.secondary)
        }
        .padding(.vertical, AppTheme.Spacing.xxSmall)
    }
}
