import Foundation
import WatchConnectivity

// MARK: - WatchConnectivityService

@Observable
@MainActor
final class WatchConnectivityService: NSObject {

    static let shared = WatchConnectivityService()

    private(set) var isReachable: Bool = false
    private var session: WCSession?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        session = wcSession
    }

    // MARK: - Send Active Workout State

    func sendWorkoutStarted(name: String) {
        send([
            WatchMessageKey.type: WatchMessageType.workoutStarted.rawValue,
            WatchMessageKey.workoutName: name,
            WatchMessageKey.isActive: true
        ])
    }

    func sendWorkoutUpdate(
        session: ActiveSession,
        elapsedSeconds: Int,
        restSecondsRemaining: Int,
        isResting: Bool
    ) {
        let currentExercise = session.exercises.first?.exerciseName ?? ""
        let currentSetCount = session.exercises.first?.sets.filter(\.isCompleted).count ?? 0
        let totalSets = session.exercises.first?.sets.count ?? 0

        send([
            WatchMessageKey.type: WatchMessageType.workoutUpdated.rawValue,
            WatchMessageKey.workoutName: session.name,
            WatchMessageKey.elapsedSeconds: elapsedSeconds,
            WatchMessageKey.currentExercise: currentExercise,
            WatchMessageKey.currentSet: currentSetCount,
            WatchMessageKey.totalSets: totalSets,
            WatchMessageKey.restSecondsRemaining: restSecondsRemaining,
            WatchMessageKey.isResting: isResting,
            WatchMessageKey.isActive: true
        ])
    }

    func sendWorkoutFinished() {
        send([
            WatchMessageKey.type: WatchMessageType.workoutFinished.rawValue,
            WatchMessageKey.isActive: false
        ])
    }

    // MARK: - Private

    private func send(_ message: [String: Any]) {
        guard let wcSession = session, wcSession.activationState == .activated else { return }
        if wcSession.isReachable {
            wcSession.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            try? wcSession.updateApplicationContext(message)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
