# FitnessNiKenneth

Native iPhone-first strength tracking app with Apple Watch companion.

## Tech Stack

- **Language**: Swift 6 (strict concurrency)
- **UI**: SwiftUI
- **Persistence**: SwiftData
- **Charts**: Swift Charts
- **Watch**: WatchConnectivity
- **Min iOS**: 18.0
- **Min watchOS**: 11.0
- **Dependencies**: None (no third-party packages)
- **Project generator**: XcodeGen 2.x

## Quick Start

```bash
# Install xcodegen (if not installed)
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open FitnessNiKenneth.xcodeproj
```

## Development Workflow

### Setup
1. `xcodegen generate` — regenerate project after changing `project.yml`
2. Open `FitnessNiKenneth.xcodeproj` in Xcode
3. Set your **Development Team** in Xcode's Signing & Capabilities (required for device/Watch)
4. Update bundle IDs if needed (`project.yml` → `bundleIdPrefix`)

### Run (Simulator)
- Select **FitnessNiKenneth** scheme + iPhone simulator → Run

### Run (Watch)
- Select **FitnessNiKenneth (Full)** scheme to build both iPhone + Watch together
- Requires watchOS simulator or physical Watch paired to a physical iPhone

### Test
```bash
xcodebuild test \
  -project FitnessNiKenneth.xcodeproj \
  -scheme FitnessNiKenneth \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FitnessNiKennethTests \
  CODE_SIGNING_ALLOWED=NO
```

### Regenerate project after schema/target changes
```bash
xcodegen generate
```

## Key Directories

```
FitnessNiKenneth/
├── App/                    Entry point, tab root
├── Core/
│   ├── Models/             SwiftData entities (Exercise, WorkoutSession, etc.)
│   ├── Services/           WorkoutEngine, AnalyticsService, SeedDataService
│   └── Design/             AppTheme, shared components
└── Features/
    ├── History/            Session list, calendar, detail
    ├── Workout/            Templates + ActiveWorkout engine UI
    └── Exercises/          Library, detail, analytics

FitnessNiKennethWatch/
├── App/                    Watch entry point
├── Views/                  Watch UI (WatchRootView, WatchActiveWorkoutView)
└── Services/               WatchWorkoutEngine (WatchConnectivity receiver)

FitnessNiKennethTests/     Unit tests (Swift Testing framework)
FitnessNiKennethUITests/   UI tests (XCTest)
docs/                       Architecture, release checklist, exercise content strategy
```

## Architecture

See `docs/ARCHITECTURE.md` for full details.

Key decisions:
- **WorkoutEngine** is `@Observable @MainActor` — owns all live workout state in memory, writes to SwiftData only at Finish
- **Analytics** are derived from persisted session data — no duplicate PR store
- **Watch** receives state via WatchConnectivity; never writes to SwiftData

## Conventions

- Conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`
- SwiftData models use raw string storage for enums (stored as `String`, exposed via computed properties)
- `#Predicate` requires local variable capture, not struct property access
- All new targets added to `project.yml` then `xcodegen generate` — never edit `.xcodeproj` directly

## Before Release

See `docs/RELEASE_CHECKLIST.md` for the full TestFlight and App Store checklist.

Key steps:
1. Set `DEVELOPMENT_TEAM` in `project.yml` (or Xcode)
2. Add 1024×1024 app icon to `Assets.xcassets/AppIcon.appiconset`
3. Add `PrivacyInfo.xcprivacy` (no data collected — mark as such)
4. Archive with **FitnessNiKenneth (Full)** scheme to embed Watch app
5. Distribute via Xcode Organizer → TestFlight

## Notes

- No HealthKit in v1 (no permissions needed)
- No iCloud sync in v1 (local-only SwiftData)
- All exercise content is original — see `docs/EXERCISE_CONTENT.md`
- The `Testing` module (Swift Testing framework) is available in Xcode 16+
