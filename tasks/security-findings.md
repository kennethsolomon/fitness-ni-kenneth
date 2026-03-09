# Security Findings

> Populated by `/security-check`. Never overwritten — new audits append below.
> Referenced by `/review`, `/finish-feature`, and `/brainstorm` for security context.

---

# Security Audit — 2026-03-09

**Scope:** Changed files on branch `feat/workout-ui-overhaul-cryo-theme`
**Stack:** Swift 6 / SwiftUI / SwiftData — iOS native (no network, no server)
**Files audited:** 12 source files + 2 test files

---

## Critical (must fix before deploy)

_None._

---

## High (fix before production)

_None._

---

## Medium (should fix)

- **[WorkoutEngine.swift:312]** `try? context.save()` silently discards SwiftData save errors after persisting the finished workout.
  **Standard:** CWE-390 (Detection of Error Condition Without Action)
  **Risk:** If the save fails (disk full, schema mismatch, etc.), the user's entire just-completed workout is silently lost with no feedback. The function returns a non-nil `WorkoutSession` object, misleading callers into thinking persistence succeeded.
  **Recommendation:** Propagate the error (`throws`) or handle it explicitly — show an alert, retry, or write to a local fallback. At minimum, `try context.save()` so the caller can catch it.

- **[WorkoutEngine.swift:317]** `try? context.save()` silently discards errors when updating `template.lastUsedAt`.
  **Standard:** CWE-390
  **Risk:** Template "last used" timestamp silently fails to update. Lower risk than above (non-critical data), but consistent with the pattern.
  **Recommendation:** Same as above — propagate or handle.

- **[WorkoutEngine.swift:369]** `try? context.fetch(descriptor).first` in `fetchExercise` silently discards fetch errors.
  **Standard:** CWE-390
  **Risk:** If the fetch fails, the `guard let exercise` skips that exercise entirely (line 286). The workout is saved without the exercise, with no user notification.
  **Recommendation:** Surface fetch failures instead of treating them the same as "exercise not found."

- **[WorkoutEngine.swift:374]** Same pattern in `fetchTemplate` — silently discards fetch errors.
  **Standard:** CWE-390
  **Risk:** Lower impact (template timestamp only), same silent failure pattern.
  **Recommendation:** Log or propagate the error.

---

## Low / Informational

- **[AppTheme.swift:15]** `Color(hex:)` falls back silently to black for invalid hex strings (non-6-digit inputs).
  **Standard:** CWE-390 (informational)
  **Recommendation:** Acceptable — hex strings are compile-time constants. No user-facing risk.

- **[WorkoutEngine.swift:183, 205]** `try? await Task.sleep(for: .seconds(1))` discards `CancellationError`. The explicit `if Task.isCancelled { return }` check immediately after compensates, but the discard is non-idiomatic.
  **Standard:** CWE-390 (informational)
  **Recommendation:** Prefer `try await Task.sleep(...)` without `?` so cancellation propagates naturally. Functionally correct as-is.

- **[ActiveExerciseSection.swift:199, ActiveWorkoutView.swift:193]** `TextEditor` for notes has no character limit.
  **Standard:** CWE-400 (Uncontrolled Resource Consumption)
  **Risk:** Minimal — local-only app. Very large notes could cause SwiftData blob bloat. Not exploitable externally.
  **Recommendation:** Consider a soft limit (e.g., 2,000 characters).

---

## Passed Checks

- No injection vulnerabilities (local SwiftData only, no SQL string formatting, no shell commands)
- No hardcoded secrets or credentials
- No network requests / SSRF exposure (fully offline app)
- No insecure data storage (SwiftData sandbox only)
- No PII handling issues, no sensitive data in logs
- No third-party dependencies (zero supply chain risk)
- Enum raw value parsing has safe fallbacks (`?? .normal`, `?? .lbs`)
- No division by zero in analytics or progress ring calculations
- Weight conversion math is safe (multiplication only)
- Task lifecycle managed correctly (`[weak self]`, tasks cancelled on finish/cancel)
- SwiftData schema defaults match Swift enum defaults
- OWASP A01–A10 (iOS equivalents: insecure local storage, data leakage, improper platform usage — all pass)

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High     | 0 |
| Medium   | 4 |
| Low      | 3 |
| **Total** | **7** |

All findings are silent error handling (`try?` on SwiftData operations). No injection, no auth bypass, no data leakage, no cryptographic failures, no supply chain risk. The local-only architecture eliminates most OWASP attack surface.

