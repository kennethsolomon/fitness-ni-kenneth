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

## Resources
- `docs/ARCHITECTURE.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/EXERCISE_CONTENT.md`
- XcodeGen docs: https://github.com/yonaskolb/XcodeGen
