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

    // MARK: - Rest Timer (new: restTotalSeconds + manual overload)

    @Test func startRestTimer_withExerciseID_setsRestTotalSeconds() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 90, exerciseID: UUID())
        #expect(engine.restTotalSeconds == 90)
        #expect(engine.isResting == true)
    }

    @Test func startRestTimer_manual_setsRestingState() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 60)
        #expect(engine.isResting == true)
        #expect(engine.restSecondsRemaining == 60)
        #expect(engine.restTotalSeconds == 60)
    }

    @Test func startRestTimer_manual_clearsActiveRestExerciseID() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 60)
        #expect(engine.activeRestExerciseID == nil)
    }

    @Test func cancelRestTimer_clearsRestTotalSeconds() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 60, exerciseID: UUID())
        engine.cancelRestTimer()
        #expect(engine.restTotalSeconds == 0)
    }

    @Test func adjustRestTimer_addsSeconds() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 60, exerciseID: UUID())
        engine.adjustRestTimer(by: 10)
        #expect(engine.restSecondsRemaining == 70)
    }

    @Test func adjustRestTimer_subtractsSeconds() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 60, exerciseID: UUID())
        engine.adjustRestTimer(by: -10)
        #expect(engine.restSecondsRemaining == 50)
    }

    @Test func adjustRestTimer_clampsToMinimumOfOne() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 5, exerciseID: UUID())
        engine.adjustRestTimer(by: -100)
        #expect(engine.restSecondsRemaining == 1)
    }

    @Test func adjustRestTimer_clampsToMaximum3600() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 3600, exerciseID: UUID())
        engine.adjustRestTimer(by: 100)
        #expect(engine.restSecondsRemaining == 3600)
    }

    @Test func adjustRestTimer_whenNotResting_doesNothing() {
        let engine = makeEngine()
        #expect(engine.isResting == false)
        engine.adjustRestTimer(by: 30)
        #expect(engine.restSecondsRemaining == 0)
    }

    @Test func adjustRestTimer_doesNotResetRestTotalSeconds() {
        let engine = makeEngine()
        engine.startRestTimer(seconds: 60, exerciseID: UUID())
        engine.adjustRestTimer(by: 10)
        #expect(engine.restTotalSeconds == 60)
        #expect(engine.restSecondsRemaining == 70)
    }

    // MARK: - Set Tag

    @Test func setTag_displayLabels_areCorrect() {
        #expect(SetTag.normal.displayLabel == "Normal")
        #expect(SetTag.warmup.displayLabel == "Warm-up")
        #expect(SetTag.dropSet.displayLabel == "Drop Set")
        #expect(SetTag.failure.displayLabel == "Failure")
    }

    @Test func setTag_badgeLabels_areCorrect() {
        #expect(SetTag.warmup.badgeLabel == "W")
        #expect(SetTag.dropSet.badgeLabel == "D")
        #expect(SetTag.failure.badgeLabel == "F")
    }

    @Test func setTag_roundtripsViaRawValue() {
        for tag in SetTag.allCases {
            #expect(SetTag(rawValue: tag.rawValue) == tag)
        }
    }

    @Test func updateSetTag_changesTagOnSet() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let setID = exercise.sets[0].id
        engine.updateSetTag(setID: setID, exerciseID: exercise.id, tag: .warmup)
        let updatedSet = engine.session?.exercises.first?.sets.first { $0.id == setID }
        #expect(updatedSet?.tag == .warmup)
    }

    @Test func updateSetTag_toFailure_persistsTag() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        let setID = exercise.sets[1].id
        engine.updateSetTag(setID: setID, exerciseID: exercise.id, tag: .failure)
        let updatedSet = engine.session?.exercises.first?.sets.first { $0.id == setID }
        #expect(updatedSet?.tag == .failure)
    }

    @Test func updateSetTag_unknownSetID_doesNotCrash() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        engine.updateSetTag(setID: UUID(), exerciseID: exercise.id, tag: .dropSet)
        #expect(engine.session?.exercises.first?.sets.first?.tag == .normal)
    }

    @Test func updateSetTag_unknownExerciseID_doesNotCrash() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        engine.updateSetTag(setID: exercise.sets[0].id, exerciseID: UUID(), tag: .failure)
        #expect(engine.session?.exercises.first?.sets.first?.tag == .normal)
    }

    // MARK: - Exercise Unit Toggle

    @Test func updateExerciseUnit_lbsToKg_convertsSetWeights() {
        let engine = makeEngine()
        let exercise = makeExercise() // sets have 135 lbs
        engine.startWorkout(name: "Test", exercises: [exercise])
        engine.updateExerciseUnit(id: exercise.id, unit: .kg)
        let convertedWeight = engine.session?.exercises.first?.sets.first?.weight ?? 0
        #expect(abs(convertedWeight - 61.235) < 0.01)
    }

    @Test func updateExerciseUnit_kgToLbs_convertsSetWeights() {
        let engine = makeEngine()
        let kgExercise = ActiveExercise(
            exerciseID: UUID(),
            exerciseName: "Squat",
            sets: [ActiveSet(weight: 100, reps: 5, unit: .kg)],
            restSeconds: 90,
            unit: .kg
        )
        engine.startWorkout(name: "Test", exercises: [kgExercise])
        engine.updateExerciseUnit(id: kgExercise.id, unit: .lbs)
        let convertedWeight = engine.session?.exercises.first?.sets.first?.weight ?? 0
        #expect(abs(convertedWeight - 220.462) < 0.01)
    }

    @Test func updateExerciseUnit_sameUnit_doesNotChangeWeights() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        engine.updateExerciseUnit(id: exercise.id, unit: .lbs)
        let weight = engine.session?.exercises.first?.sets.first?.weight ?? 0
        #expect(weight == 135)
    }

    @Test func updateExerciseUnit_updatesExerciseUnitProperty() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        #expect(engine.session?.exercises.first?.unit == .lbs)
        engine.updateExerciseUnit(id: exercise.id, unit: .kg)
        #expect(engine.session?.exercises.first?.unit == .kg)
    }

    @Test func updateExerciseUnit_updatesAllSetUnits() {
        let engine = makeEngine()
        let exercise = makeExercise()
        engine.startWorkout(name: "Test", exercises: [exercise])
        engine.updateExerciseUnit(id: exercise.id, unit: .kg)
        let sets = engine.session?.exercises.first?.sets ?? []
        #expect(sets.allSatisfy { $0.unit == .kg })
    }
}
