import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var name: String
    var startedAt: Date
    var finishedAt: Date?
    var notes: String
    var templateID: UUID?
    var cachedDurationSeconds: Double

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.session)
    var exercises: [WorkoutExercise]

    init(
        id: UUID = UUID(),
        name: String,
        startedAt: Date = Date(),
        templateID: UUID? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.finishedAt = nil
        self.notes = notes
        self.templateID = templateID
        self.cachedDurationSeconds = 0
        self.exercises = []
    }

    var duration: TimeInterval {
        if cachedDurationSeconds > 0 { return cachedDurationSeconds }
        guard let finishedAt else { return Date().timeIntervalSince(startedAt) }
        return finishedAt.timeIntervalSince(startedAt)
    }

    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var totalVolume: Double {
        exercises.flatMap(\.sets).filter(\.isCompleted).reduce(0) { acc, set in
            acc + (set.weight * Double(set.reps))
        }
    }

    var completedSetsCount: Int {
        exercises.flatMap(\.sets).filter(\.isCompleted).count
    }
}

@Model
final class WorkoutExercise {
    var id: UUID
    var order: Int
    var notes: String
    var restSeconds: Int

    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet]

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        session: WorkoutSession,
        order: Int,
        notes: String = "",
        restSeconds: Int = 90
    ) {
        self.id = id
        self.order = order
        self.notes = notes
        self.restSeconds = restSeconds
        self.exercise = exercise
        self.session = session
        self.sets = []
    }

    var sortedSets: [WorkoutSet] {
        sets.sorted { $0.order < $1.order }
    }

    var completedSets: [WorkoutSet] {
        sortedSets.filter(\.isCompleted)
    }

    var totalVolume: Double {
        completedSets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }
}

@Model
final class WorkoutSet {
    var id: UUID
    var order: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var completedAt: Date?
    var unitRaw: String

    var workoutExercise: WorkoutExercise?

    init(
        id: UUID = UUID(),
        workoutExercise: WorkoutExercise,
        order: Int,
        weight: Double = 0,
        reps: Int = 0,
        unit: WeightUnit = .lbs
    ) {
        self.id = id
        self.order = order
        self.weight = weight
        self.reps = reps
        self.isCompleted = false
        self.completedAt = nil
        self.unitRaw = unit.rawValue
        self.workoutExercise = workoutExercise
    }

    var unit: WeightUnit {
        WeightUnit(rawValue: unitRaw) ?? .lbs
    }

    var estimated1RM: Double {
        AnalyticsFormulas.epleyOneRepMax(weight: weight, reps: reps)
    }

    var volume: Double {
        weight * Double(reps)
    }
}
