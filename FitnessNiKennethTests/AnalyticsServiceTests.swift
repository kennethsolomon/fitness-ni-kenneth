import Foundation
import Testing
import SwiftData
@testable import FitnessNiKenneth

// MARK: - Analytics Tests

struct AnalyticsServiceTests {

    // MARK: - Epley 1RM Formula

    @Test func epley_singleRep_returnsWeight() {
        let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: 100, reps: 1)
        #expect(oneRM == 100)
    }

    @Test func epley_zeroReps_returnsZero() {
        let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: 100, reps: 0)
        #expect(oneRM == 0)
    }

    @Test func epley_zeroWeight_returnsZero() {
        let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: 0, reps: 10)
        #expect(oneRM == 0)
    }

    @Test func epley_knownValues() {
        // 100kg × 10 reps → 100 × (1 + 10/30) = 100 × 1.333... = 133.33
        let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: 100, reps: 10)
        #expect(abs(oneRM - 133.333) < 0.1)
    }

    @Test func epley_5reps_knownValue() {
        // 225lbs × 5 reps → 225 × (1 + 5/30) = 225 × 1.1667 = 262.5
        let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: 225, reps: 5)
        #expect(abs(oneRM - 262.5) < 0.1)
    }

    // MARK: - Total Volume

    @Test func volume_multiplyWeightByReps() {
        let volume = AnalyticsFormulas.totalVolume(weight: 100, reps: 10)
        #expect(volume == 1000)
    }

    @Test func volume_zeroWeight() {
        let volume = AnalyticsFormulas.totalVolume(weight: 0, reps: 10)
        #expect(volume == 0)
    }

    // MARK: - Best Set

    @MainActor
    @Test func bestSet_returnsSetWithHighestEstimated1RM() async throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let exerciseID = UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000001")!
        let exercise = Exercise(
            id: exerciseID,
            name: "Bench Press",
            primaryMuscles: [.chest],
            equipment: .barbell,
            category: .push,
            instructions: ""
        )
        context.insert(exercise)

        let session1 = WorkoutSession(name: "Session 1")
        session1.finishedAt = Date()
        session1.cachedDurationSeconds = 3600
        context.insert(session1)

        let we1 = WorkoutExercise(exercise: exercise, session: session1, order: 0)
        context.insert(we1)

        let set1 = WorkoutSet(workoutExercise: we1, order: 0, weight: 100, reps: 10, unit: .lbs)
        set1.isCompleted = true
        context.insert(set1)

        let set2 = WorkoutSet(workoutExercise: we1, order: 1, weight: 120, reps: 5, unit: .lbs)
        set2.isCompleted = true
        context.insert(set2)

        try context.save()

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let best = AnalyticsService.bestSet(for: exerciseID, in: sessions)

        // 100 × (1 + 10/30) = 133.33
        // 120 × (1 + 5/30) = 140
        // best should be 120 × 5
        #expect(best?.weight == 120)
        #expect(best?.reps == 5)
    }

    @MainActor
    @Test func previousPerformance_returnsLastSession() async throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let exerciseID = UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000002")!
        let exercise = Exercise(
            id: exerciseID,
            name: "Squat",
            primaryMuscles: [.quads],
            equipment: .barbell,
            category: .squat,
            instructions: ""
        )
        context.insert(exercise)

        let pastDate = Date().addingTimeInterval(-86400)
        let session1 = WorkoutSession(name: "Session 1", startedAt: pastDate)
        session1.finishedAt = pastDate.addingTimeInterval(3600)
        session1.cachedDurationSeconds = 3600
        context.insert(session1)

        let we1 = WorkoutExercise(exercise: exercise, session: session1, order: 0)
        context.insert(we1)

        let set1 = WorkoutSet(workoutExercise: we1, order: 0, weight: 225, reps: 5, unit: .lbs)
        set1.isCompleted = true
        context.insert(set1)

        try context.save()

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let prev = AnalyticsService.previousPerformance(exerciseID: exerciseID, before: Date(), in: sessions)

        #expect(prev.count == 1)
        #expect(prev.first?.weight == 225)
        #expect(prev.first?.reps == 5)
    }

    @MainActor
    @Test func newPRs_detectsImprovement() async throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let exerciseID = UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000003")!
        let exercise = Exercise(
            id: exerciseID,
            name: "Deadlift",
            primaryMuscles: [.back],
            equipment: .barbell,
            category: .hinge,
            instructions: ""
        )
        context.insert(exercise)

        // Historical session with 225 × 5
        let session1 = WorkoutSession(name: "Old Session", startedAt: Date().addingTimeInterval(-86400))
        session1.finishedAt = Date().addingTimeInterval(-82800)
        session1.cachedDurationSeconds = 3600
        context.insert(session1)

        let we1 = WorkoutExercise(exercise: exercise, session: session1, order: 0)
        context.insert(we1)

        let oldSet = WorkoutSet(workoutExercise: we1, order: 0, weight: 225, reps: 5, unit: .lbs)
        oldSet.isCompleted = true
        context.insert(oldSet)

        // New session with 275 × 3 (higher 1RM)
        let session2 = WorkoutSession(name: "New Session")
        session2.finishedAt = Date()
        session2.cachedDurationSeconds = 3600
        context.insert(session2)

        let we2 = WorkoutExercise(exercise: exercise, session: session2, order: 0)
        context.insert(we2)

        let newSet = WorkoutSet(workoutExercise: we2, order: 0, weight: 275, reps: 3, unit: .lbs)
        newSet.isCompleted = true
        context.insert(newSet)

        try context.save()

        let allSessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let prs = AnalyticsService.newPRs(in: session2, comparedTo: allSessions)

        #expect(prs.contains(exerciseID))
    }

    @MainActor
    @Test func newPRs_doesNotFlagNonPR() async throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let exerciseID = UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000004")!
        let exercise = Exercise(
            id: exerciseID,
            name: "Curl",
            primaryMuscles: [.biceps],
            equipment: .barbell,
            category: .pull,
            instructions: ""
        )
        context.insert(exercise)

        // Historical session with 100 × 10 (1RM ≈ 133)
        let session1 = WorkoutSession(name: "Old Session", startedAt: Date().addingTimeInterval(-86400))
        session1.finishedAt = Date().addingTimeInterval(-82800)
        session1.cachedDurationSeconds = 3600
        context.insert(session1)

        let we1 = WorkoutExercise(exercise: exercise, session: session1, order: 0)
        context.insert(we1)

        let oldSet = WorkoutSet(workoutExercise: we1, order: 0, weight: 100, reps: 10, unit: .lbs)
        oldSet.isCompleted = true
        context.insert(oldSet)

        // New session with 80 × 8 (lower 1RM)
        let session2 = WorkoutSession(name: "New Session")
        session2.finishedAt = Date()
        session2.cachedDurationSeconds = 3600
        context.insert(session2)

        let we2 = WorkoutExercise(exercise: exercise, session: session2, order: 0)
        context.insert(we2)

        let newSet = WorkoutSet(workoutExercise: we2, order: 0, weight: 80, reps: 8, unit: .lbs)
        newSet.isCompleted = true
        context.insert(newSet)

        try context.save()

        let allSessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let prs = AnalyticsService.newPRs(in: session2, comparedTo: allSessions)

        #expect(!prs.contains(exerciseID))
    }

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
}
