# Lessons Learned

Accumulated patterns from past bugs and corrections. Read this file at the **start of any task** and apply all active lessons before proceeding. Add a new entry whenever a recurrent mistake is identified.

## Entry Format

```markdown
### [YYYY-MM-DD] [Brief title]
**Bug:** What went wrong (symptom)
**Root cause:** Why it happened
**Prevention:** What to do differently next time
```

## Active Lessons

<!-- Add entries here. Remove a lesson only when the root cause is permanently fixed in the codebase. -->

### [2026-03-09] XcodeGen: new files require regeneration
**Bug:** New Swift files added after `xcodegen generate` are missing from the `.xcodeproj` — compiler can't find types from those files.
**Root cause:** XcodeGen scans directories at generation time; it doesn't auto-update.
**Prevention:** Always run `xcodegen generate` after adding, moving, or deleting Swift files. Never edit `.xcodeproj` manually.

### [2026-03-09] Swift 6: WCSession is not Sendable
**Bug:** `sending 'session' risks causing data races` when passing `WCSession` into `Task { @MainActor }`.
**Root cause:** `WCSession` is a reference type without `Sendable` conformance.
**Prevention:** Extract any primitive values you need (e.g. `let reachable = session.isReachable`) before the actor hop. Never send the `WCSession` object itself across actor boundaries.

### [2026-03-09] SwiftData `#Predicate` cannot capture struct properties
**Bug:** `cannot convert value of type ... to closure result type` when using a struct's property directly in `#Predicate`.
**Root cause:** The `#Predicate` macro requires the captured value to be a simple local constant, not a property path through a value type.
**Prevention:** Always assign `let id = myStruct.property` before the `#Predicate { $0.id == id }` call.

### [2026-03-09] Swift: `set` as property name causes "Expected '{' to start setter definition"
**Bug:** Computed property `private var foo: String { set.property }` fails with "Expected '{' to start setter definition".
**Root cause:** `set` is a contextual keyword in Swift property declarations. When it appears as the first token inside a computed property body `{ ... }`, the parser treats it as a setter definition.
**Prevention:** When a stored property is named `set`, always use `let tag = set.xxx; return tag` or add explicit `return set.xxx` as the first token. Better: rename the property to `activeSet` or similar inside views to avoid ambiguity entirely.

### [2026-03-09] watchOS simulator required even for iOS-only test runs (when watch is a build dependency)
**Bug:** `No available simulator runtimes for platform watchsimulator` when running tests via the full scheme.
**Root cause:** The Watch target was a build dependency of the iOS target, so Xcode tried to build it for the watch simulator.
**Prevention:** Use two schemes — one iOS-only (`FitnessNiKenneth`) for tests/dev, one full (`FitnessNiKenneth (Full)`) for Watch builds. Remove the explicit target dependency from `project.yml`.

