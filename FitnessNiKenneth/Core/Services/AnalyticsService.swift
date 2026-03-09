import Foundation
import SwiftData

// MARK: - AnalyticsService

/// Pure analytics computation. All methods are nonisolated and safe to call from any context.
/// Accepts pre-fetched data to keep SwiftData context usage on the caller's actor.
struct AnalyticsService: Sendable {

    // MARK: - Best Set

    static func bestSet(
        for exerciseID: UUID,
        in sessions: [WorkoutSession]
    ) -> WorkoutSetSnapshot? {
        var best: WorkoutSetSnapshot?

        for session in sessions {
            guard let finishedAt = session.finishedAt else { continue }
            for workoutExercise in session.exercises {
                guard workoutExercise.exercise?.id == exerciseID else { continue }
                for set in workoutExercise.sets where set.isCompleted && set.reps > 0 && set.weight > 0 {
                    let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: set.weight, reps: set.reps)
                    let current = best.map {
                        AnalyticsFormulas.epleyOneRepMax(weight: $0.weight, reps: $0.reps)
                    } ?? 0

                    if oneRM > current {
                        best = WorkoutSetSnapshot(
                            weight: set.weight,
                            reps: set.reps,
                            unit: set.unit,
                            tag: set.tag,
                            sessionID: session.id,
                            sessionDate: finishedAt,
                            sessionName: session.name
                        )
                    }
                }
            }
        }
        return best
    }

    // MARK: - 1RM History

    static func oneRMHistory(
        for exerciseID: UUID,
        in sessions: [WorkoutSession]
    ) -> [OneRMDataPoint] {
        var points: [OneRMDataPoint] = []

        let sortedSessions = sessions
            .filter { $0.finishedAt != nil }
            .sorted { $0.startedAt < $1.startedAt }

        for session in sortedSessions {
            guard let finishedAt = session.finishedAt else { continue }
            var sessionBest: (oneRM: Double, weight: Double, reps: Int)?

            for workoutExercise in session.exercises {
                guard workoutExercise.exercise?.id == exerciseID else { continue }
                for set in workoutExercise.sets where set.isCompleted && set.reps > 0 && set.weight > 0 {
                    let oneRM = AnalyticsFormulas.epleyOneRepMax(weight: set.weight, reps: set.reps)
                    if oneRM > (sessionBest?.oneRM ?? 0) {
                        sessionBest = (oneRM, set.weight, set.reps)
                    }
                }
            }

            if let best = sessionBest {
                points.append(OneRMDataPoint(
                    id: UUID(),
                    date: finishedAt,
                    oneRM: best.oneRM,
                    weight: best.weight,
                    reps: best.reps,
                    sessionName: session.name
                ))
            }
        }
        return points
    }

    // MARK: - Volume History

    static func volumeHistory(
        for exerciseID: UUID,
        in sessions: [WorkoutSession]
    ) -> [VolumeDataPoint] {
        var points: [VolumeDataPoint] = []

        let sortedSessions = sessions
            .filter { $0.finishedAt != nil }
            .sorted { $0.startedAt < $1.startedAt }

        for session in sortedSessions {
            guard let finishedAt = session.finishedAt else { continue }
            var sessionVolume = 0.0

            for workoutExercise in session.exercises {
                guard workoutExercise.exercise?.id == exerciseID else { continue }
                for set in workoutExercise.sets where set.isCompleted {
                    sessionVolume += AnalyticsFormulas.totalVolume(weight: set.weight, reps: set.reps)
                }
            }

            if sessionVolume > 0 {
                points.append(VolumeDataPoint(
                    id: UUID(),
                    date: finishedAt,
                    volume: sessionVolume,
                    sessionName: session.name
                ))
            }
        }
        return points
    }

    // MARK: - Session Volume History

    static func sessionVolumeHistory(in sessions: [WorkoutSession]) -> [VolumeDataPoint] {
        sessions
            .filter { $0.finishedAt != nil }
            .sorted { $0.startedAt < $1.startedAt }
            .map { session in
                VolumeDataPoint(
                    id: session.id,
                    date: session.finishedAt ?? session.startedAt,
                    volume: session.totalVolume,
                    sessionName: session.name
                )
            }
    }

    // MARK: - PR Detection After Workout

    /// Returns exercise IDs with new all-time 1RM PRs set during the given session.
    static func newPRs(
        in session: WorkoutSession,
        comparedTo historicalSessions: [WorkoutSession]
    ) -> [UUID] {
        var prExerciseIDs: [UUID] = []
        let historicalOnly = historicalSessions.filter { $0.id != session.id }

        for workoutExercise in session.exercises {
            guard let exerciseID = workoutExercise.exercise?.id else { continue }

            let sessionBest = workoutExercise.completedSets
                .filter { $0.reps > 0 && $0.weight > 0 }
                .map { AnalyticsFormulas.epleyOneRepMax(weight: $0.weight, reps: $0.reps) }
                .max() ?? 0

            guard sessionBest > 0 else { continue }

            let historicalBest = bestSet(for: exerciseID, in: historicalOnly)
            let previousBest = historicalBest.map {
                AnalyticsFormulas.epleyOneRepMax(weight: $0.weight, reps: $0.reps)
            } ?? 0

            if sessionBest > previousBest {
                prExerciseIDs.append(exerciseID)
            }
        }
        return prExerciseIDs
    }

    // MARK: - Previous Performance

    /// Returns the most recent completed sets for an exercise before the current session.
    static func previousPerformance(
        exerciseID: UUID,
        before date: Date,
        in sessions: [WorkoutSession]
    ) -> [WorkoutSetSnapshot] {
        let relevantSessions = sessions
            .filter { $0.finishedAt != nil && $0.startedAt < date }
            .sorted { $0.startedAt > $1.startedAt }

        for session in relevantSessions {
            for workoutExercise in session.exercises {
                guard workoutExercise.exercise?.id == exerciseID else { continue }
                let completed = workoutExercise.sortedSets.filter(\.isCompleted)
                guard !completed.isEmpty else { continue }
                return completed.map {
                    WorkoutSetSnapshot(
                        weight: $0.weight,
                        reps: $0.reps,
                        unit: $0.unit,
                        tag: $0.tag,
                        sessionID: session.id,
                        sessionDate: session.finishedAt ?? session.startedAt,
                        sessionName: session.name
                    )
                }
            }
        }
        return []
    }

    // MARK: - Max Reps

    static func maxReps(for exerciseID: UUID, in sessions: [WorkoutSession]) -> Int {
        sessions.flatMap { session in
            session.exercises.filter { $0.exercise?.id == exerciseID }
                .flatMap { $0.sets.filter(\.isCompleted) }
                .map(\.reps)
        }.max() ?? 0
    }

    // MARK: - Total Sessions

    static func sessionCount(for exerciseID: UUID, in sessions: [WorkoutSession]) -> Int {
        sessions.filter { session in
            session.exercises.contains { $0.exercise?.id == exerciseID }
        }.count
    }
}
