# Findings — 2026-03-09 — FitnessNiKenneth Project Stack

## Requirements
- Native iPhone-first strength tracking app (Strong-inspired, no copied content)
- Apple Watch companion
- Local-first (SwiftData, no iCloud in v1)
- Production-ready quality for App Store

## Repo / Stack Notes

| Item | Value |
|------|-------|
| Language | Swift 6 (strict concurrency enabled) |
| UI | SwiftUI |
| Persistence | SwiftData (iOS 18+) |
| Charts | Swift Charts |
| Watch | WatchConnectivity |
| Min iOS | 18.0 |
| Min watchOS | 11.0 |
| Xcode | 26.2 (iOS 26.2 SDK) |
| Project generator | XcodeGen 2.45.2 (`project.yml` → `.xcodeproj`) |
| Third-party deps | None |
| Test framework | Swift Testing (unit) + XCTest (UI) |

### Key paths
- `project.yml` — XcodeGen spec; run `xcodegen generate` after changes
- `FitnessNiKenneth/Core/Models/` — SwiftData entities
- `FitnessNiKenneth/Core/Services/WorkoutEngine.swift` — live session state machine
- `FitnessNiKenneth/Core/Services/AnalyticsService.swift` — pure analytics functions
- `FitnessNiKenneth/Core/Services/SeedDataService.swift` — exercise library + starter templates
- `FitnessNiKenneth/Core/Services/NotificationService.swift` — rest timer notifications + haptics
- `FitnessNiKennethWatch/` — Watch companion (WatchConnectivity-driven)
- `FitnessNiKennethTests/` — 34 unit tests (all passing)
- `docs/ARCHITECTURE.md` — full architecture reference
- `docs/RELEASE_CHECKLIST.md` — TestFlight + App Store steps

### Build commands
```bash
# Generate .xcodeproj (always after project.yml changes or new files)
xcodegen generate

# Build iOS (no signing, simulator)
xcodebuild -project FitnessNiKenneth.xcodeproj -target FitnessNiKenneth \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO build

# Run unit tests
xcodebuild test -project FitnessNiKenneth.xcodeproj \
  -scheme FitnessNiKenneth \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FitnessNiKennethTests CODE_SIGNING_ALLOWED=NO
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| SwiftData over CoreData | iOS 18 target, Swift 6 native, no boilerplate |
| WorkoutEngine in-memory during workout | No SwiftData writes per set = no UI jank during live workout |
| Analytics derived from sessions | No duplicate PR store that can drift out of sync |
| No HealthKit in v1 | Avoids permission complexity; deferred to v2 |
| No iCloud in v1 | Local-first; CloudKit deferred to v2 |
| XcodeGen for project | Avoids committing xcodeproj conflicts; declarative |
| Two schemes | `FitnessNiKenneth` (iOS only, tests) + `FitnessNiKenneth (Full)` (iOS + Watch) |

---

# Findings — 2026-03-09 — Active Workout UI Overhaul

## Problem Statement
The active workout screen needs 4 improvements to match the reference app (Strong-style UX):
1. Set type tagging (warm-up, drop set, failure) per set
2. Rest timer redesigned as a toolbar button + sheet with circular progress ring
3. Number keyboard does not dismiss after entering weight/reps
4. Per-exercise unit toggle (lbs ↔ kg) with value conversion

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `SetTag` enum stored as raw String in `WorkoutSet` | Matches existing pattern for enums in SwiftData models |
| Set badge → context menu (not cycle on tap) | Reduces accidental mis-tags; matches reference image |
| `restTotalSeconds` added to `WorkoutEngine` | Required to compute progress arc % in countdown ring |
| `adjustRestTimer(by:)` added to engine | Supports -10s/+10s buttons in countdown sheet |
| Auto-rest (set completion) stays silent | Sheet does NOT auto-open; toolbar button turns blue |
| Manual rest (tap idle button) → preset picker first | Mirrors reference app flow |
| Custom timer uses native wheel picker | Matches iOS conventions; user confirmed option A |
| Per-exercise unit stored on `ActiveExercise` | Allows column header to update and values to convert |
| Cancel button moved to bottom strip below Add Exercise | Reduces accidental cancellation; matches reference layout |
| Keyboard dismiss via `.toolbar { ToolbarItemGroup(.keyboard) }` | Clean iOS pattern, no tap-gesture hacks needed |

## Chosen Approach: Direct implementation, no new abstractions

All changes are additive or small edits to existing files. No new service layers needed.

## Scope of Changes

### New types (SharedTypes.swift)
- `SetTag` enum: `.normal`, `.warmup`, `.dropSet`, `.failure`
- `ActiveSet` gains `tag: SetTag`
- `ActiveExercise` gains `unit: WeightUnit` (exercise-level, defaults to `.lbs`)

### WorkoutEngine.swift
- Add `restTotalSeconds: Int` (tracked on `startRestTimer`)
- Add `adjustRestTimer(by seconds: Int)` (clamps to 1...3600)
- Add `startRestTimer(seconds: Int)` overload without exerciseID (manual start)
- Add `updateSetTag(setID:exerciseID:tag:)`
- Add `updateExerciseUnit(id:unit:)` (converts all set weights)

### WorkoutSet.swift (SwiftData model)
- Add `tagRaw: String` stored property
- Add computed `tag: SetTag`

### WorkoutSetSnapshot (SharedTypes.swift)
- Add `tag: SetTag` (shows "(F)", "(W)", "(D)" in Previous column)

### ActiveWorkoutView.swift
- Remove `restTimerBanner`
- Toolbar: replace Cancel + Notes with `TimerToolbarButton` (leading) + Finish (trailing)
- Add Cancel strip at bottom below Add Exercise bar

### ActiveExerciseSection.swift
- Column header: dynamic "LBS" / "KG" per exercise unit
- Exercise "..." menu: add "Change Unit" option
- `addSetButton` label: shows rest hint "+ Add Set (2:00)" when restSeconds > 0

### ActiveSetRow.swift
- Set number badge: tappable with `.contextMenu` for tag options
- Badge color: normal = dark, W = blue, D = purple, F = red
- Weight/reps TextFields: add `ToolbarItemGroup(placement: .keyboard)` Done button

### New view: RestTimerSheet.swift
- State 1 — Preset picker: decorative blue circle ring, list (0:30 / 1:00 / 2:00 / 3:00), "Create Custom Timer" button
- State 2 — Countdown: depleting arc ring, large current time + smaller total time, -10s / +10s / Skip
- "Create Custom Timer": native `DateComponentsPicker` wheel for minutes + seconds
- Triggered from toolbar button; sheet dismiss leaves timer running

### New view: TimerToolbarButton.swift
- Idle: dark rounded square with `⟳` icon
- Active: blue pill capsule showing `⟳ M:SS`

## Open Questions
- None — all clarifications resolved

## Resources
- `docs/ARCHITECTURE.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/EXERCISE_CONTENT.md`
- XcodeGen docs: https://github.com/yonaskolb/XcodeGen
