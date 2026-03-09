# Architecture

## Overview

**FitnessNiKenneth** is a native iPhone-first strength tracking app with an Apple Watch companion. The architecture is modular, feature-driven, and local-first.

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI |
| Persistence | SwiftData (iOS 18+) |
| Charts | Swift Charts |
| Watch Communication | WatchConnectivity |
| Minimum iOS | 18.0 |
| Minimum watchOS | 11.0 |
| No third-party dependencies | — |

## Module Structure

```
FitnessNiKenneth/
├── App/                        Entry point, tab root
├── Core/
│   ├── Models/                 SwiftData entities
│   ├── Services/               Business logic (stateless + stateful)
│   └── Design/                 AppTheme + shared components
└── Features/
    ├── History/                Past sessions, calendar, detail
    ├── Workout/
    │   ├── Templates/          Template CRUD
    │   └── ActiveWorkout/      Live workout engine UI
    └── Exercises/              Exercise library + detail + analytics

FitnessNiKennethWatch/
├── App/                        Watch entry point
├── Views/                      Watch UI screens
└── Services/                   WatchConnectivity receiver
```

## Domain Model

```
Exercise                 Master exercise definition
  └── WorkoutExercise    Exercise instance within a session

WorkoutTemplate
  └── TemplateExercise   Ordered exercise slot in a template

WorkoutSession           A completed (or in-progress) workout
  └── WorkoutExercise    Exercise performed
      └── WorkoutSet     Single set (weight × reps)
```

All analytics (1RM, volume, PRs) are **derived** from `WorkoutSession` / `WorkoutSet` data. There is no separate PR store that can drift out of sync.

## WorkoutEngine

`WorkoutEngine` is an `@Observable @MainActor` class that owns all live session state:

- Holds a draft `[ActiveExercise]` array in memory during workout (no SwiftData writes during sets for maximum UI speed)
- Manages elapsed timer and per-exercise rest timer using `Task`-based async loops
- On **Finish**: writes the entire session to SwiftData in one transaction, then evaluates PRs
- On **Cancel**: discards all state

## Persistence

`ModelContainer` is configured with `VersionedSchema` from day 1. This enables safe lightweight migrations as the schema evolves post-v1.

The container is configured in `FitnessNiKennethApp` and injected via `.modelContainer()`.

## Analytics

`AnalyticsService` is a pure-function service that accepts `[WorkoutSession]` and returns derived metrics:

- **Estimated 1RM**: Epley formula — `weight × (1 + reps / 30)`
- **Best set**: highest estimated 1RM across all sets for an exercise
- **Total volume**: Σ(weight × reps) for completed sets
- **PR detection**: compare new session 1RM against historical best

## Watch Companion

The Watch app does **not** share SwiftData with the iPhone. The iPhone's `WatchConnectivityService` sends active session snapshots via `WCSession.sendMessage()` when:

- Workout starts / ends
- Set is completed
- Rest timer starts / stops

The Watch app receives these via `WCSessionDelegate` and updates its `@Observable` local state. The Watch never writes to SwiftData.

## Concurrency

- All UI + SwiftData work runs on `@MainActor`
- `AnalyticsService` pure functions are `nonisolated` and can be called from any context
- `WatchConnectivityService` dispatches WCSession callbacks to `@MainActor`
- Timers use `Task { @MainActor in ... }` with `try await Task.sleep()`

## Design System

`AppTheme` defines:
- Color palette (semantic colors that adapt to light/dark)
- Typography scale
- Spacing constants
- Shared view modifiers

No external design libraries are used.
