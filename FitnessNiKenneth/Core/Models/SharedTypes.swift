import Foundation

// MARK: - Weight Unit

enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case lbs
    case kg

    var label: String { rawValue }

    func convert(_ value: Double, to target: WeightUnit) -> Double {
        guard self != target else { return value }
        return target == .kg ? value * 0.453592 : value * 2.20462
    }
}

// MARK: - Muscle Group

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case quads
    case hamstrings
    case glutes
    case calves
    case core
    case traps
    case lats

    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .forearms: "Forearms"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .glutes: "Glutes"
        case .calves: "Calves"
        case .core: "Core"
        case .traps: "Traps"
        case .lats: "Lats"
        }
    }
}

// MARK: - Equipment

enum Equipment: String, Codable, CaseIterable, Sendable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case kettlebell
    case ezBar = "ez_bar"
    case smithMachine = "smith_machine"
    case resistanceBand = "resistance_band"
    case other

    var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .cable: "Cable"
        case .machine: "Machine"
        case .bodyweight: "Bodyweight"
        case .kettlebell: "Kettlebell"
        case .ezBar: "EZ Bar"
        case .smithMachine: "Smith Machine"
        case .resistanceBand: "Resistance Band"
        case .other: "Other"
        }
    }
}

// MARK: - Movement Category

enum MovementCategory: String, Codable, CaseIterable, Sendable {
    case push
    case pull
    case squat
    case hinge
    case carry
    case core
    case isolation

    var displayName: String {
        switch self {
        case .push: "Push"
        case .pull: "Pull"
        case .squat: "Squat"
        case .hinge: "Hinge"
        case .carry: "Carry"
        case .core: "Core"
        case .isolation: "Isolation"
        }
    }
}

// MARK: - Active Session Types (in-memory, not persisted)

struct ActiveSet: Identifiable, Sendable {
    let id: UUID
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var completedAt: Date?
    var unit: WeightUnit

    init(id: UUID = UUID(), weight: Double = 0, reps: Int = 0, unit: WeightUnit = .lbs) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.isCompleted = false
        self.completedAt = nil
        self.unit = unit
    }
}

struct ActiveExercise: Identifiable, Sendable {
    let id: UUID
    let exerciseID: UUID
    let exerciseName: String
    var sets: [ActiveSet]
    var notes: String
    var restSeconds: Int
    var order: Int

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        exerciseName: String,
        sets: [ActiveSet] = [],
        notes: String = "",
        restSeconds: Int = 90,
        order: Int = 0
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.sets = sets
        self.notes = notes
        self.restSeconds = restSeconds
        self.order = order
    }
}

struct ActiveSession: Sendable {
    let id: UUID
    var name: String
    let startedAt: Date
    var exercises: [ActiveExercise]
    var notes: String
    let templateID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        startedAt: Date = Date(),
        exercises: [ActiveExercise] = [],
        notes: String = "",
        templateID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.exercises = exercises
        self.notes = notes
        self.templateID = templateID
    }
}

// MARK: - Analytics Types

struct ExerciseStats: Sendable {
    let exerciseID: UUID
    let bestSet: WorkoutSetSnapshot?
    let estimated1RM: Double
    let totalVolume: Double
    let sessionCount: Int
}

struct WorkoutSetSnapshot: Sendable {
    let weight: Double
    let reps: Int
    let unit: WeightUnit
    let sessionID: UUID
    let sessionDate: Date
    let sessionName: String

    var estimated1RM: Double {
        AnalyticsFormulas.epleyOneRepMax(weight: weight, reps: reps)
    }
}

struct VolumeDataPoint: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let volume: Double
    let sessionName: String
}

struct OneRMDataPoint: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let oneRM: Double
    let weight: Double
    let reps: Int
    let sessionName: String
}

// MARK: - Analytics Formulas (pure, nonisolated)

enum AnalyticsFormulas {
    static func epleyOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps > 0, weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    static func totalVolume(weight: Double, reps: Int) -> Double {
        weight * Double(reps)
    }
}

// MARK: - Watch Message Keys

enum WatchMessageKey {
    static let type = "type"
    static let workoutName = "workoutName"
    static let elapsedSeconds = "elapsedSeconds"
    static let currentExercise = "currentExercise"
    static let currentSet = "currentSet"
    static let totalSets = "totalSets"
    static let restSecondsRemaining = "restSecondsRemaining"
    static let isResting = "isResting"
    static let isActive = "isActive"
}

enum WatchMessageType: String {
    case workoutStarted
    case workoutUpdated
    case workoutFinished
    case completeSet
    case startRest
    case stopRest
}
