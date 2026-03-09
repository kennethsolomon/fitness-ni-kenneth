# Exercise Content Strategy

## Principles

1. **Original content only** — all exercise instructions, tips, and descriptions are written from first principles using established biomechanical knowledge. No content is scraped from Strong, Jefit, or any other app.
2. **Text-first** — v1 ships with text instructions and no media. The data model supports `imageName` and `videoURL` fields for future expansion.
3. **Curated, not exhaustive** — a curated set of ~65 foundational exercises covering all major movement patterns and muscle groups.

## Exercise Data Model

Each exercise in `ExerciseData.json` includes:

| Field | Type | Description |
|---|---|---|
| `id` | UUID string | Stable identifier for seeding |
| `name` | String | Primary name |
| `aliases` | [String] | Alternative names users might search |
| `primaryMuscles` | [MuscleGroup] | Main muscles targeted |
| `secondaryMuscles` | [MuscleGroup] | Synergists and stabilizers |
| `equipment` | Equipment | Required equipment |
| `category` | MovementCategory | Movement pattern |
| `instructions` | String | Step-by-step how-to |
| `tips` | String | Coaching cues |
| `commonMistakes` | String | What to avoid |
| `imageName` | String? | Future: asset name |
| `isCustom` | Bool | false for seeded exercises |

## Movement Categories

- **Push** — horizontal and vertical pushing movements
- **Pull** — horizontal and vertical pulling movements
- **Squat** — knee-dominant leg exercises
- **Hinge** — hip-dominant leg exercises
- **Carry** — loaded carry patterns
- **Core** — trunk stability and flexion
- **Isolation** — single-joint accessory movements

## Muscle Groups

Primary: chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core, forearms, traps

## Equipment

barbell, dumbbell, cable, machine, bodyweight, kettlebell, ezBar, smithMachine, resistanceBand, other

## Adding Custom Exercises

Users can add custom exercises via the Exercise Library tab. Custom exercises:
- Are flagged `isCustom = true`
- Can be deleted (seeded exercises cannot be deleted)
- Support all the same fields
- Appear in the exercise picker during workouts

## Future Media Expansion

When adding exercise media in a future version:
1. Add images to `Assets.xcassets` as named image sets
2. Set `imageName` on the relevant exercise
3. The `ExerciseDetailView` already checks for `imageName` and shows a placeholder if nil
4. For video, add a `videoURL` field to the Exercise model and handle with `AVPlayer`
