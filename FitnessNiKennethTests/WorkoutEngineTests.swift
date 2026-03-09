import Foundation
import Testing
import SwiftData
@testable import FitnessNiKenneth

// MARK: - WorkoutEngine Tests

@MainActor
struct WorkoutEngineTests {

    // MARK: - Helpers

    private func makeEngine() -> WorkoutEngine {
        WorkoutEngine()
    }

    private func makeExercise() -> ActiveExercise {
        ActiveExercise(
            exerciseID: UUID(),
            exerciseName: "Bench Press",
            sets: [
                ActiveSet(weight: 135, reps: 8, unit: .lbs),
                ActiveSet(weight: 135, reps: 8, unit: .lbs),
            ],
            restSeconds: 90
        )
    }

    // MARK: - Start Workout

    @Test func startWorkout_setsActiveSession() {
        let engine = makeEngine()
        engine.startWorkout(name: "Push Day", exercises: [])
        #expect(engine.isActive == true)
        #expect(engine.session?.name == "Push Day")
    }

    @Test func startEmptyWorkout_hasNonEmptyName() {
        let engine = makeEngine()
        engine.startEmptyWorkout()
        #expect(engine.isActive == true)
        #expect(!(engine.session?.name.isEmpty ?? true))
    }

    @Test func cancelWorkout_clearsSession() {
        let engine = makeEngine()
        engine.startWorkout(name: "Test", exercises: [])
        engine.cancelWorkout()
        #expect(engine.isActive == false)
        #expect(engine.session == nil)
    }

    // MARK: - Exercises

    @Test func addExercise_appendsToSession() {
        let engine = makeEngine()
        engine.startWorkout(name: "Test", exercises: [])
        let exerciseID = UUID()
        engine.addExercise(exerciseID: exerciseID, exerciseName: "Squat")
        #expect(engine.session?.exercises.count == 1)
        #expect(engine.session?.exercises.first?.exerciseName == "Squat")
    }

    @Test func removeExercise_removesFromSession() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        engine.removeExercise(id: exercise.id)
        #expect(engine.session?.exercises.isEmpty == true)
    }

    @Test func replaceExercise_changesExerciseName() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let newID = UUID()
        engine.replaceExercise(id: exercise.id, with: newID, exerciseName: "Squat")
        #expect(engine.session?.exercises.first?.exerciseName == "Squat")
        #expect(engine.session?.exercises.first?.exerciseID == newID)
    }

    // MARK: - Sets

    @Test func addSet_appendsSetToExercise() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let initialCount = exercise.sets.count
        engine.addSet(to: exercise.id)
        #expect(engine.session?.exercises.first?.sets.count == initialCount + 1)
    }

    @Test func removeSet_removesSetFromExercise() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let setToRemove = exercise.sets[0]
        engine.removeSet(setID: setToRemove.id, from: exercise.id)
        #expect(engine.session?.exercises.first?.sets.count == 1)
    }

    @Test func updateSet_updatesWeightAndReps() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let setID = exercise.sets[0].id
        engine.updateSet(setID: setID, exerciseID: exercise.id, weight: 225, reps: 5, unit: .lbs)
        let updatedSet = engine.session?.exercises.first?.sets.first { $0.id == setID }
        #expect(updatedSet?.weight == 225)
        #expect(updatedSet?.reps == 5)
    }

    @Test func toggleSetCompletion_completesSet() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let setID = exercise.sets[0].id
        #expect(engine.session?.exercises.first?.sets.first?.isCompleted == false)
        engine.toggleSetCompletion(setID: setID, exerciseID: exercise.id)
        #expect(engine.session?.exercises.first?.sets.first?.isCompleted == true)
    }

    @Test func toggleSetCompletion_uncompleteCompletedSet() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let setID = exercise.sets[0].id
        engine.toggleSetCompletion(setID: setID, exerciseID: exercise.id)
        engine.toggleSetCompletion(setID: setID, exerciseID: exercise.id)
        #expect(engine.session?.exercises.first?.sets.first?.isCompleted == false)
    }

    // MARK: - Rest Timer

    @Test func startRestTimer_setsRestingState() async throws {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 5, exerciseID: UUID())
        #expect(engine.isResting == true)
        #expect(engine.restSecondsRemaining == 5)
    }

    @Test func cancelRestTimer_clearsRestingState() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 60, exerciseID: UUID())
        engine.cancelRestTimer()
        #expect(engine.isResting == false)
        #expect(engine.restSecondsRemaining == 0)
    }

    // MARK: - Unit Conversion

    @Test func weightUnitConversion_lbsToKg() {
        let converted = WeightUnit.lbs.convert(100, to: .kg)
        #expect(abs(converted - 45.3592) < 0.001)
    }

    @Test func weightUnitConversion_kgToLbs() {
        let converted = WeightUnit.kg.convert(100, to: .lbs)
        #expect(abs(converted - 220.462) < 0.001)
    }

    @Test func weightUnitConversion_sameUnit() {
        let converted = WeightUnit.lbs.convert(100, to: .lbs)
        #expect(converted == 100)
    }
}
