import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastUsedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.lastUsedAt = nil
        self.exercises = []
    }

    var sortedExercises: [TemplateExercise] {
        exercises.sorted { $0.order < $1.order }
    }
}

@Model
final class TemplateExercise {
    var id: UUID
    var order: Int
    var defaultSets: Int
    var defaultReps: Int
    var defaultWeight: Double
    var defaultUnitRaw: String
    var restSeconds: Int

    var template: WorkoutTemplate?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        order: Int,
        defaultSets: Int = 3,
        defaultReps: Int = 10,
        defaultWeight: Double = 0,
        defaultUnit: WeightUnit = .lbs,
        restSeconds: Int = 90
    ) {
        self.id = id
        self.order = order
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.defaultUnitRaw = defaultUnit.rawValue
        self.restSeconds = restSeconds
        self.exercise = exercise
    }

    var defaultUnit: WeightUnit {
        WeightUnit(rawValue: defaultUnitRaw) ?? .lbs
    }
}
