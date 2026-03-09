import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var aliases: [String]
    var primaryMusclesRaw: [String]
    var secondaryMusclesRaw: [String]
    var equipmentRaw: String
    var categoryRaw: String
    var instructions: String
    var tips: String
    var commonMistakes: String
    var isCustom: Bool
    var imageName: String?
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var workoutExercises: [WorkoutExercise]

    init(
        id: UUID = UUID(),
        name: String,
        aliases: [String] = [],
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        equipment: Equipment,
        category: MovementCategory,
        instructions: String,
        tips: String = "",
        commonMistakes: String = "",
        isCustom: Bool = false,
        imageName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.primaryMusclesRaw = primaryMuscles.map(\.rawValue)
        self.secondaryMusclesRaw = secondaryMuscles.map(\.rawValue)
        self.equipmentRaw = equipment.rawValue
        self.categoryRaw = category.rawValue
        self.instructions = instructions
        self.tips = tips
        self.commonMistakes = commonMistakes
        self.isCustom = isCustom
        self.imageName = imageName
        self.createdAt = Date()
        self.workoutExercises = []
    }

    var primaryMuscles: [MuscleGroup] {
        primaryMusclesRaw.compactMap(MuscleGroup.init(rawValue:))
    }

    var secondaryMuscles: [MuscleGroup] {
        secondaryMusclesRaw.compactMap(MuscleGroup.init(rawValue:))
    }

    var equipment: Equipment {
        Equipment(rawValue: equipmentRaw) ?? .other
    }

    var category: MovementCategory {
        MovementCategory(rawValue: categoryRaw) ?? .isolation
    }

    var allMuscles: [MuscleGroup] {
        primaryMuscles + secondaryMuscles
    }

    var primaryMuscleDisplayString: String {
        primaryMuscles.map(\.displayName).joined(separator: ", ")
    }
}
