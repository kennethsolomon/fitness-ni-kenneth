import Foundation
import WatchConnectivity

// MARK: - WatchWorkoutEngine

/// Receives workout state from the iPhone via WatchConnectivity.
/// Never writes to disk — purely mirrors the iPhone's WorkoutEngine state.
@Observable
@MainActor
final class WatchWorkoutEngine: NSObject {

    private(set) var isActive: Bool = false
    private(set) var workoutName: String = ""
    private(set) var elapsedSeconds: Int = 0
    private(set) var currentExercise: String = ""
    private(set) var currentSet: Int = 0
    private(set) var totalSets: Int = 0
    private(set) var restSecondsRemaining: Int = 0
    private(set) var isResting: Bool = false

    private var elapsedTimerTask: Task<Void, Never>?

    override init() {
        super.init()
        activateWCSession()
    }

    // MARK: - WatchConnectivity

    private func activateWCSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func applyMessage(_ message: [String: Any]) {
        let type = message[WatchMessageKey.type] as? String ?? ""

        switch WatchMessageType(rawValue: type) {
        case .workoutStarted:
            isActive = true
            workoutName = message[WatchMessageKey.workoutName] as? String ?? ""
            elapsedSeconds = 0
            startElapsedTimer()

        case .workoutUpdated:
            isActive = true
            workoutName = message[WatchMessageKey.workoutName] as? String ?? ""
            elapsedSeconds = message[WatchMessageKey.elapsedSeconds] as? Int ?? elapsedSeconds
            currentExercise = message[WatchMessageKey.currentExercise] as? String ?? ""
            currentSet = message[WatchMessageKey.currentSet] as? Int ?? 0
            totalSets = message[WatchMessageKey.totalSets] as? Int ?? 0
            restSecondsRemaining = message[WatchMessageKey.restSecondsRemaining] as? Int ?? 0
            isResting = message[WatchMessageKey.isResting] as? Bool ?? false

        case .workoutFinished:
            isActive = false
            elapsedTimerTask?.cancel()
            resetState()

        default:
            break
        }
    }

    // MARK: - Local elapsed timer (increments between iPhone updates)

    private func startElapsedTimer() {
        elapsedTimerTask?.cancel()
        elapsedTimerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                if isActive { elapsedSeconds += 1 }
                if isResting && restSecondsRemaining > 0 { restSecondsRemaining -= 1 }
            }
        }
    }

    private func resetState() {
        workoutName = ""
        elapsedSeconds = 0
        currentExercise = ""
        currentSet = 0
        totalSets = 0
        restSecondsRemaining = 0
        isResting = false
    }
}

// MARK: - WCSessionDelegate

extension WatchWorkoutEngine: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            self.applyMessage(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            self.applyMessage(applicationContext)
        }
    }
}
