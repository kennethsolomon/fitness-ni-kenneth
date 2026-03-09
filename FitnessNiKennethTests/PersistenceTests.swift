import Foundation
import Testing
import SwiftData
@testable import FitnessNiKenneth

// MARK: - Persistence Tests

@MainActor
struct PersistenceTests {

    // MARK: - Helpers

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            WorkoutSession.self,
            WorkoutExercise.self,
            WorkoutSet.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    // MARK: - SeedData

    @Test func seedData_insertsExercises() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        SeedDataService.seedIfNeeded(context: context)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count > 0)
    }

    @Test func seedData_insertsTemplates() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        SeedDataService.seedIfNeeded(context: context)

        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        #expect(templates.count > 0)
    }

    @Test func seedData_idempotent() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        SeedDataService.seedIfNeeded(context: context)
        let countAfterFirst = try context.fetch(FetchDescriptor<Exercise>()).count

        SeedDataService.seedIfNeeded(context: context)
        let countAfterSecond = try context.fetch(FetchDescriptor<Exercise>()).count

        #expect(countAfterFirst == countAfterSecond)
    }

    // MARK: - WorkoutSession Persistence

    @Test func workoutSession_savesAndReloads() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let session = WorkoutSession(name: "Test Session")
        session.finishedAt = Date()
        session.cachedDurationSeconds = 3600
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Test Session")
    }

    @Test func workoutSet_persistsCompletionState() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let exercise = Exercise(
            name: "Test Exercise",
            primaryMuscles: [.chest],
            equipment: .barbell,
            category: .push,
            instructions: ""
        )
        context.insert(exercise)

        let session = WorkoutSession(name: "Test")
        session.finishedAt = Date()
        context.insert(session)

        let workoutExercise = WorkoutExercise(exercise: exercise, session: session, order: 0)
        context.insert(workoutExercise)

        let set = WorkoutSet(workoutExercise: workoutExercise, order: 0, weight: 135, reps: 8, unit: .lbs)
        set.isCompleted = true
        set.completedAt = Date()
        context.insert(set)

        try context.save()

        let fetchedSets = try context.fetch(FetchDescriptor<WorkoutSet>())
        #expect(fetchedSets.first?.isCompleted == true)
        #expect(fetchedSets.first?.weight == 135)
        #expect(fetchedSets.first?.reps == 8)
    }

    // MARK: - Template Persistence

    @Test func template_savesExercises() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let exercise = Exercise(
            name: "Bench Press",
            primaryMuscles: [.chest],
            equipment: .barbell,
            category: .push,
            instructions: ""
        )
        context.insert(exercise)

        let template = WorkoutTemplate(name: "Push Day")
        context.insert(template)

        let te = TemplateExercise(
            exercise: exercise,
            order: 0,
            defaultSets: 4,
            defaultReps: 8,
            defaultWeight: 135
        )
        te.template = template
        context.insert(te)

        try context.save()

        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        #expect(templates.first?.exercises.count == 1)
        #expect(templates.first?.exercises.first?.defaultSets == 4)
    }

    // MARK: - WorkoutEngine Finish Integration

    @Test func workoutEngine_finishWorkout_persistsSession() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let exercise = Exercise(
            id: UUID(),
            name: "Squat",
            primaryMuscles: [.quads],
            equipment: .barbell,
            category: .squat,
            instructions: ""
        )
        context.insert(exercise)
        try context.save()

        let engine = WorkoutEngine()
        let activeExercise = ActiveExercise(
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            sets: [
                ActiveSet(weight: 225, reps: 5, unit: .lbs),
                ActiveSet(weight: 225, reps: 5, unit: .lbs),
            ]
        )
        engine.startWorkout(name: "Test Workout", exercises: [activeExercise])
        engine.toggleSetCompletion(setID: activeExercise.sets[0].id, exerciseID: activeExercise.id)

        let savedSession = engine.finishWorkout(context: context)
        #expect(savedSession != nil)
        #expect(savedSession?.name == "Test Workout")

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.finishedAt != nil)
    }
}
