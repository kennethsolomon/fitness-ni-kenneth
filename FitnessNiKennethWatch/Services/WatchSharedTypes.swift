import Foundation

// Mirror of WatchMessageKey / WatchMessageType from the iPhone app.
// Kept in sync manually — these are the contract between iOS and watchOS.

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
