# TODO — 2026-03-09 — Active Workout UI Overhaul + Cryo Theme

## Goal
Redesign the active workout screen with 4 features (set type tags, rest timer toolbar sheet,
keyboard dismiss, per-exercise unit toggle) and apply the Nocturnal Cryo-Lab color theme
across the entire app.

---

## Lessons Applied (from tasks/lessons.md)
- Run `xcodegen generate` after every new file added or deleted
- Do not pass `WCSession` across actor boundaries — extract primitives first
- Use `let x = struct.property` before any `#Predicate { $0.field == x }`
- Use `FitnessNiKenneth` (iOS-only) scheme for all test/build verification

---

## Plan

### Phase 1 — Design System (AppTheme)
- [ ] 1.1 Add `Color(hex:)` extension to `AppTheme.swift`
- [ ] 1.2 Replace all system-adaptive colors in `AppTheme.Colors` with Cryo palette hex values
       (background #0D0B12, card #1A1625, row #221B2E, separator #2E2540,
        accent/Purple Pain #8458B3, primary/Freeze Purple #e5eaf5,
        secondary/Heavy Purple #a28089, restTimerActive/Ice Cold #a0d2eb,
        completedSet #8458B3, prBadge #FFD700)
- [ ] 1.3 Add new named colors: `iceCold`, `mediumPurple`, `purplePain`, `heavyPurple`,
       `warmupBadge`, `dropSetBadge`, `failureBadge`
- [ ] 1.4 Add `timerCountdown` font: `.system(size: 72, weight: .bold, design: .rounded)`
- [ ] 1.5 Add `columnHeader` font: `.system(size: 11, weight: .heavy)` with tracking 1.2
- [ ] 1.6 Update `Assets.xcassets/AccentColor` hex to `#8458B3`

### Phase 2 — Data Model: New Types (SharedTypes.swift)
- [ ] 2.1 Add `SetTag` enum (`.normal`, `.warmup`, `.dropSet`, `.failure`) with `rawValue: String`
       and `displayLabel: String` (e.g. "Warm-up", "Drop Set", "Failure")
- [ ] 2.2 Add `tag: SetTag` to `ActiveSet` struct (default `.normal`)
- [ ] 2.3 Update `ActiveSet.init` to accept optional `tag` parameter
- [ ] 2.4 Add `unit: WeightUnit` to `ActiveExercise` struct (default `.lbs`)
- [ ] 2.5 Update `ActiveExercise.init` to accept optional `unit` parameter
- [ ] 2.6 Add `tag: SetTag` to `WorkoutSetSnapshot` struct

### Phase 3 — Data Model: SwiftData (WorkoutSession.swift)
- [ ] 3.1 Add `tagRaw: String` stored property to `WorkoutSet` (default `"normal"` in init)
- [ ] 3.2 Add computed `var tag: SetTag` to `WorkoutSet`
       (uses `SetTag(rawValue: tagRaw) ?? .normal`)

### Phase 4 — WorkoutEngine.swift
- [ ] 4.1 Add `private(set) var restTotalSeconds: Int = 0` property
- [ ] 4.2 Update existing `startRestTimer(seconds:exerciseID:)` to set `restTotalSeconds = seconds`
- [ ] 4.3 Add `startRestTimer(seconds:)` overload (no exerciseID — for manual timer starts)
       Sets `activeRestExerciseID = nil`
- [ ] 4.4 Add `func adjustRestTimer(by delta: Int)` — clamps result to `1...3600`,
       cancels notification, reschedules with remaining time, does NOT reset `restTotalSeconds`
- [ ] 4.5 Add `func updateSetTag(setID: UUID, exerciseID: UUID, tag: SetTag)`
- [ ] 4.6 Add `func updateExerciseUnit(id: UUID, unit: WeightUnit)` —
       converts all set weights using `WeightUnit.convert(_:to:)`, updates `exercise.unit`

### Phase 5 — WorkoutEngine.finishWorkout (persist tag)
- [ ] 5.1 In `finishWorkout`, set `workoutSet.tagRaw = activeSet.tag.rawValue` when
       creating `WorkoutSet` objects

### Phase 6 — AnalyticsService.swift
- [ ] 6.1 Find where `WorkoutSetSnapshot` is constructed — add `tag: set.tag` field
- [ ] 6.2 Verify `previousPerformance` snapshots carry the tag through to display

### Phase 7 — New view: TimerToolbarButton.swift
- [ ] 7.1 Create `FitnessNiKenneth/Features/Workout/ActiveWorkout/TimerToolbarButton.swift`
- [ ] 7.2 Idle state: dark rounded square (36×36, cornerRadius 10, bg #221B2E),
       "timer" SF Symbol 18pt, Heavy Purple color
- [ ] 7.3 Active state: Capsule (height 36), Ice Cold (#a0d2eb) background,
       "timer" SF Symbol 14pt + Text(countdown) — dark text (#0D0B12)
       Text uses `.contentTransition(.numericText(countsDown: true))`
- [ ] 7.4 Transition between states animated with `.spring(response: 0.4, dampingFraction: 0.8)`
- [ ] 7.5 Run `xcodegen generate`

### Phase 8 — New view: RestTimerSheet.swift
- [ ] 8.1 Create `FitnessNiKenneth/Features/Workout/ActiveWorkout/RestTimerSheet.swift`
- [ ] 8.2 Implement `RestTimerSheet` as a `View` with two states driven by a local
       `@State private var showCustomPicker: Bool` and engine's `isResting`
- [ ] 8.3 State A — Preset Picker (shown when `!workoutEngine.isResting && !showCustomPicker`):
       - X close button (top left, calls `dismiss()`)
       - Title "Rest Timer", subtitle in Heavy Purple
       - Decorative Circle ring (stroke, Ice Cold, 3pt, full)
       - Inside: `VStack` with 4 preset Button rows: 0:30 / 1:00 / 2:00 / 3:00
         Each tapped row calls `workoutEngine.startRestTimer(seconds:)` then `dismiss()`
       - "Create Custom Timer" full-width dark card button at bottom
- [ ] 8.4 State B — Active Countdown (shown when `workoutEngine.isResting`):
       - Same X close button + title
       - Subtitle "Adjust duration via the +/− buttons."
       - `ZStack`: background Circle (track, #221B2E, 6pt), foreground `Circle().trim`
         from 0 to `progress` (stroke, Ice Cold, 6pt, lineCap .round, rotated -90°)
         `progress = Double(workoutEngine.restSecondsRemaining) / Double(workoutEngine.restTotalSeconds)`
         animated with `.animation(.linear(duration: 1.0), value: progress)`
       - Center: large countdown `Text` (timerCountdown font, Freeze Purple),
         smaller total `Text` (subheadline, Heavy Purple)
       - Bottom row: `−10s` button, `+10s` button, `Skip` capsule (Purple Pain bg)
- [ ] 8.5 State C — Custom Picker (shown when `showCustomPicker`):
       - Two `Picker` wheels side by side: minutes (0–59) and seconds (0–59)
       - "Start Timer" full-width Purple Pain button
       - Tapping Start: calls `workoutEngine.startRestTimer(seconds: mins*60+secs)`, clears flag, `dismiss()`
- [ ] 8.6 Run `xcodegen generate`

### Phase 9 — Update ActiveWorkoutView.swift
- [ ] 9.1 Remove `restTimerBanner` view and its call site in `workoutContent`
- [ ] 9.2 Remove `isResting` conditional wrapping `restTimerBanner`
- [ ] 9.3 Replace toolbar leading `Button("Cancel")` with `TimerToolbarButton`
       that sets `@State private var showRestTimerSheet = true` on tap
- [ ] 9.4 Remove Notes button from trailing toolbar (or keep — decision: keep it,
       move to a `...` menu inline with the workout title per image 1)
- [ ] 9.5 Add `.sheet(isPresented: $showRestTimerSheet) { RestTimerSheet() }` to toolbar button
- [ ] 9.6 Move Cancel to bottom: add `cancelWorkoutButton` below `addExerciseBar` in the
       `ZStack` bottom strip — destructive text button "Cancel Workout"
- [ ] 9.7 Add `preferredColorScheme(.dark)` to root `NavigationStack`
- [ ] 9.8 Update elapsed timer banner gradient to Purple Pain (was `accent.gradient`)

### Phase 10 — Update ActiveExerciseSection.swift
- [ ] 10.1 Column header: replace hardcoded `"LBS"` with `exercise.unit.label.uppercased()`
- [ ] 10.2 Add "Change Unit" to exercise `...` Menu:
        `Button { workoutEngine.updateExerciseUnit(id: exercise.id, unit: toggled) }`
        label shows current unit and toggle target ("Switch to KG" / "Switch to LBS")
- [ ] 10.3 `addSetButton` label: show rest time hint when `exercise.restSeconds > 0`:
        `"+ Add Set (\(exercise.restSeconds.restTimerFormatted))"`
- [ ] 10.4 Remove the per-exercise rest-timer inline display in `exerciseHeader`
        (the "Rest: 1:30" text) — now surfaced in the add-set button hint

### Phase 11 — Update ActiveSetRow.swift
- [ ] 11.1 Replace plain `Text("\(setNumber)")` with a `SetBadgeView` (inline helper in same file):
        - Shape: RoundedRectangle(cornerRadius: 8), 28×28
        - Normal: bg #221B2E, text Freeze Purple, setNumber displayed
        - Warmup: bg iceCold@20%, text iceCold, border iceCold@40% 1pt, shows "W"
        - Drop: bg mediumPurple@20%, text mediumPurple, border mediumPurple@40% 1pt, shows "D"
        - Failure: bg purplePain@30%, text purplePain, border purplePain@50% 1pt, shows "F"
        - Font: `.system(size: 13, weight: .bold, design: .rounded)`
- [ ] 11.2 Add `.contextMenu` to the badge:
        4 `Button` items: "Normal", "Warm-up", "Drop Set", "Failure"
        Each calls `workoutEngine.updateSetTag(setID: set.id, exerciseID: exerciseID, tag: .xxx)`
        Add `Label` with system icons: "1.circle", "flame", "arrow.down.circle", "exclamationmark.circle"
- [ ] 11.3 Animate badge color change: `.animation(.spring(response: 0.25, dampingFraction: 0.65), value: set.tag)`
- [ ] 11.4 Add keyboard Done button to both TextFields:
        `.toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { weightFocused = false; repsFocused = false } } }`
- [ ] 11.5 Previous performance display: append tag suffix when tag != .normal
        e.g. `"30 kg × 5 (W)"`, `"40 kg × 7 (F)"` — update the prev Text formatter

### Phase 12 — Build verification
- [ ] 12.1 Run `xcodegen generate`
- [ ] 12.2 Build: `xcodebuild -project FitnessNiKenneth.xcodeproj -target FitnessNiKenneth -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build`
- [ ] 12.3 Fix any compiler errors (Swift 6 strict concurrency, missing Sendable, etc.)
- [ ] 12.4 Run unit tests: `xcodebuild test -project FitnessNiKenneth.xcodeproj -scheme FitnessNiKenneth -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FitnessNiKennethTests CODE_SIGNING_ALLOWED=NO`
- [ ] 12.5 Confirm all 34 existing tests still pass

### Phase 13 — App Icon
- [ ] 13.1 Create "Cold Iron" app icon: barbell tilted 12°, Ice Cold (#a0d2eb) on dark
        radial gradient (#2D1B5E center → #0D0B12 edges), Medium Purple glow behind barbell
        Add to `Assets.xcassets/AppIcon.appiconset` at 1024×1024

---

## Verification

```bash
# Full build (no signing)
xcodebuild -project FitnessNiKenneth.xcodeproj \
  -target FitnessNiKenneth \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO build

# All unit tests pass
xcodebuild test -project FitnessNiKenneth.xcodeproj \
  -scheme FitnessNiKenneth \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FitnessNiKennethTests \
  CODE_SIGNING_ALLOWED=NO
# Expected: ** TEST SUCCEEDED ** — 34 tests passing
```

---

## Acceptance Criteria
- [ ] Set badge shows W/D/F/number with correct Cryo colors; context menu changes tag
- [ ] Completing a set silently starts the rest timer; toolbar button turns blue pill with countdown
- [ ] Tapping idle timer button opens preset picker sheet
- [ ] Tapping active timer button opens countdown sheet with progress ring
- [ ] Dismissing sheet leaves timer running in toolbar button
- [ ] -10s / +10s adjust the countdown correctly; Skip cancels
- [ ] Custom timer picker lets user set minutes+seconds and start timer
- [ ] Number keyboard shows "Done" button that dismisses focus
- [ ] Exercise "..." menu has "Switch to KG / Switch to LBS" — values convert
- [ ] Column header shows "KG" or "LBS" per exercise
- [ ] "Cancel Workout" is at bottom below Add Exercise
- [ ] All backgrounds are dark (#0D0B12); cards are #1A1625; accent is Purple Pain
- [ ] All 34 unit tests pass after changes

---

## Risks / Unknowns
- SwiftData adding `tagRaw` to existing `WorkoutSet`: if users have existing data, the
  field defaults to `"normal"` via init — lightweight migration should handle this
  automatically. If it fails, the fix is adding `@Attribute(.externalStorage)` or
  making the field optional. Low risk since app is pre-release.
- `workoutEngine.restTotalSeconds` being 0 when `isResting` first ticks: guard with
  `max(1, restTotalSeconds)` in the progress calculation to avoid divide-by-zero.
- iOS 18 `DateComponentsPicker` API: not available — use two `Picker` wheels instead.
- `preferredColorScheme(.dark)`: locks the app to dark mode globally. Confirm this is
  intentional (Cryo aesthetic is dark-only).

---

## Results
- (fill after execution)

## Errors
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |
