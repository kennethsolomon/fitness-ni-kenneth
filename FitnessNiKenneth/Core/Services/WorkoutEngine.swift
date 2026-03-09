import Foundation
import SwiftData

// MARK: - WorkoutEngine

/// Owns all live workout state. Runs entirely on the main actor.
/// Does NOT write to SwiftData during the workout — writes happen only at finish.
@Observable
@MainActor
final class WorkoutEngine {

    // MARK: - Published State

    private(set) var session: ActiveSession?
    private(set) var elapsedSeconds: Int = 0
    private(set) var restSecondsRemaining: Int = 0
    private(set) var isResting: Bool = false
    private(set) var activeRestExerciseID: UUID?

    var isActive: Bool { session != nil }

    // MARK: - Private

    private var workoutTimerTask: Task<Void, Never>?
    private var restTimerTask: Task<Void, Never>?
    private var onWatchUpdate: ((ActiveSession, Int, Int, Bool) -> Void)?

    // MARK: - Start

    func startWorkout(name: String, exercises: [ActiveExercise], templateID: UUID? = nil) {
        cancelRestTimer()
        workoutTimerTask?.cancel()

        let newSession = ActiveSession(
            name: name,
            exercises: exercises,
            templateID: templateID
        )
        session = newSession
        elapsedSeconds = 0
        startWorkoutTimer()
        onWatchUpdate?(newSession, elapsedSeconds, restSecondsRemaining, isResting)
    }

    func startEmptyWorkout() {
        startWorkout(name: formattedWorkoutName(), exercises: [])
    }

    // MARK: - Exercises

    func addExercise(exerciseID: UUID, exerciseName: String, restSeconds: Int = 90) {
        guard var current = session else { return }
        let order = current.exercises.count
        let newExercise = ActiveExercise(
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            sets: [defaultSet()],
            restSeconds: restSeconds,
            order: order
        )
        current.exercises.append(newExercise)
        session = current
    }

    func removeExercise(id: UUID) {
        guard var current = session else { return }
        current.exercises.removeAll { $0.id == id }
        for idx in current.exercises.indices {
            current.exercises[idx].order = idx
        }
        session = current
    }

    func replaceExercise(id: UUID, with exerciseID: UUID, exerciseName: String) {
        guard var current = session,
              let idx = current.exercises.firstIndex(where: { $0.id == id }) else { return }
        var replacement = current.exercises[idx]
        let newExercise = ActiveExercise(
            id: replacement.id,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            sets: replacement.sets,
            notes: replacement.notes,
            restSeconds: replacement.restSeconds,
            order: replacement.order
        )
        current.exercises[idx] = newExercise
        session = current
    }

    func updateExerciseNotes(id: UUID, notes: String) {
        guard var current = session,
              let idx = current.exercises.firstIndex(where: { $0.id == id }) else { return }
        current.exercises[idx].notes = notes
        session = current
    }

    func updateExerciseRestTime(id: UUID, seconds: Int) {
        guard var current = session,
              let idx = current.exercises.firstIndex(where: { $0.id == id }) else { return }
        current.exercises[idx].restSeconds = seconds
        session = current
    }

    // MARK: - Sets

    func addSet(to exerciseID: UUID) {
        guard var current = session,
              let idx = current.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        let lastSet = current.exercises[idx].sets.last
        let newSet = ActiveSet(
            weight: lastSet?.weight ?? 0,
            reps: lastSet?.reps ?? 0,
            unit: lastSet?.unit ?? .lbs
        )
        current.exercises[idx].sets.append(newSet)
        session = current
    }

    func removeSet(setID: UUID, from exerciseID: UUID) {
        guard var current = session,
              let exIdx = current.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        current.exercises[exIdx].sets.removeAll { $0.id == setID }
        session = current
    }

    func updateSet(setID: UUID, exerciseID: UUID, weight: Double, reps: Int, unit: WeightUnit) {
        guard var current = session,
              let exIdx = current.exercises.firstIndex(where: { $0.id == exerciseID }),
              let setIdx = current.exercises[exIdx].sets.firstIndex(where: { $0.id == setID }) else { return }
        current.exercises[exIdx].sets[setIdx].weight = weight
        current.exercises[exIdx].sets[setIdx].reps = reps
        current.exercises[exIdx].sets[setIdx].unit = unit
        session = current
    }

    func toggleSetCompletion(setID: UUID, exerciseID: UUID) {
        guard var current = session,
              let exIdx = current.exercises.firstIndex(where: { $0.id == exerciseID }),
              let setIdx = current.exercises[exIdx].sets.firstIndex(where: { $0.id == setID }) else { return }

        let wasCompleted = current.exercises[exIdx].sets[setIdx].isCompleted
        current.exercises[exIdx].sets[setIdx].isCompleted = !wasCompleted

        if !wasCompleted {
            current.exercises[exIdx].sets[setIdx].completedAt = Date()
            let restSecs = current.exercises[exIdx].restSeconds
            session = current
            NotificationService.hapticSetComplete()
            startRestTimer(seconds: restSecs, exerciseID: exerciseID)
        } else {
            current.exercises[exIdx].sets[setIdx].completedAt = nil
            session = current
        }

        onWatchUpdate?(current, elapsedSeconds, restSecondsRemaining, isResting)
    }

    // MARK: - Session Notes

    func updateSessionNotes(_ notes: String) {
        guard var current = session else { return }
        current.notes = notes
        session = current
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int, exerciseID: UUID) {
        cancelRestTimer()
        guard seconds > 0 else { return }
        restSecondsRemaining = seconds
        isResting = true
        activeRestExerciseID = exerciseID

        NotificationService.scheduleRestEnd(after: seconds)

        restTimerTask = Task { [weak self] in
            guard let self else { return }
            while restSecondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                restSecondsRemaining -= 1
            }
            isResting = false
            activeRestExerciseID = nil
            NotificationService.hapticRestComplete()
        }
    }

    func cancelRestTimer() {
        restTimerTask?.cancel()
        restTimerTask = nil
        restSecondsRemaining = 0
        isResting = false
        activeRestExerciseID = nil
        NotificationService.cancelRestEnd()
    }

    func resetRestTimer(for exerciseID: UUID) {
        guard var current = session,
              let exercise = current.exercises.first(where: { $0.id == exerciseID }) else { return }
        startRestTimer(seconds: exercise.restSeconds, exerciseID: exerciseID)
    }

    // MARK: - Finish / Cancel

    func finishWorkout(context: ModelContext) -> WorkoutSession? {
        guard let current = session else { return nil }

        workoutTimerTask?.cancel()
        cancelRestTimer()

        let finishedAt = Date()
        let duration = finishedAt.timeIntervalSince(current.startedAt)

        let workoutSession = WorkoutSession(
            id: current.id,
            name: current.name,
            startedAt: current.startedAt,
            templateID: current.templateID,
            notes: current.notes
        )
        workoutSession.finishedAt = finishedAt
        workoutSession.cachedDurationSeconds = duration

        context.insert(workoutSession)

        for activeExercise in current.exercises {
            guard let exercise = fetchExercise(id: activeExercise.exerciseID, context: context) else { continue }

            let workoutExercise = WorkoutExercise(
                exercise: exercise,
                session: workoutSession,
                order: activeExercise.order,
                notes: activeExercise.notes,
                restSeconds: activeExercise.restSeconds
            )
            context.insert(workoutExercise)

            for (index, activeSet) in activeExercise.sets.enumerated() {
                let workoutSet = WorkoutSet(
                    workoutExercise: workoutExercise,
                    order: index,
                    weight: activeSet.weight,
                    reps: activeSet.reps,
                    unit: activeSet.unit
                )
                workoutSet.isCompleted = activeSet.isCompleted
                workoutSet.completedAt = activeSet.completedAt
                context.insert(workoutSet)
            }
        }

        try? context.save()

        if let templateID = current.templateID,
           let template = fetchTemplate(id: templateID, context: context) {
            template.lastUsedAt = Date()
            try? context.save()
        }

        session = nil
        elapsedSeconds = 0
        return workoutSession
    }

    func cancelWorkout() {
        workoutTimerTask?.cancel()
        cancelRestTimer()
        session = nil
        elapsedSeconds = 0
    }

    // MARK: - Watch Callback

    func setWatchUpdateHandler(_ handler: @escaping (ActiveSession, Int, Int, Bool) -> Void) {
        self.onWatchUpdate = handler
    }

    // MARK: - Private Helpers

    private func startWorkoutTimer() {
        workoutTimerTask?.cancel()
        workoutTimerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                elapsedSeconds += 1
                if let current = session {
                    onWatchUpdate?(current, elapsedSeconds, restSecondsRemaining, isResting)
                }
            }
        }
    }

    private func defaultSet() -> ActiveSet {
        ActiveSet(weight: 0, reps: 0, unit: .lbs)
    }

    private func formattedWorkoutName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Workout – \(formatter.string(from: Date()))"
    }

    private func fetchExercise(id: UUID, context: ModelContext) -> Exercise? {
        var descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchTemplate(id: UUID, context: ModelContext) -> WorkoutTemplate? {
        var descriptor = FetchDescriptor<WorkoutTemplate>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
