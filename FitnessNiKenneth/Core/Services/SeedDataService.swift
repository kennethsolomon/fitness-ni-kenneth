import Foundation
import SwiftData

// MARK: - SeedDataService

struct SeedDataService {

    /// Seeds the database with starter exercises and templates if not already seeded.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<Exercise>()
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let exercises = makeExercises()
        for exercise in exercises {
            context.insert(exercise)
        }

        let templates = makeTemplates(exercises: exercises)
        for template in templates {
            context.insert(template)
        }

        try? context.save()
    }

    // MARK: - Exercise Library

    // swiftlint:disable function_body_length
    static func makeExercises() -> [Exercise] {
        [
            // MARK: Chest
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
                name: "Barbell Bench Press",
                aliases: ["Bench Press", "Flat Bench Press", "Chest Press"],
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps, .shoulders],
                equipment: .barbell,
                category: .push,
                instructions: "1. Lie flat on a bench with your feet flat on the floor.\n2. Grip the barbell slightly wider than shoulder-width with an overhand grip.\n3. Unrack the bar and hold it directly above your chest with arms fully extended.\n4. Lower the bar in a controlled arc to your mid-chest, keeping elbows at roughly 45–75° from your torso.\n5. Press the bar back up to the starting position, driving through your chest and triceps.\n6. Lock out at the top without hyperextending.",
                tips: "Keep your shoulder blades retracted and depressed throughout. Maintain a slight arch in your lower back. Drive your feet into the floor for a stable base. Think about 'bending the bar' to engage your lats.",
                commonMistakes: "Flaring elbows to 90° (increases shoulder impingement risk). Bouncing the bar off the chest. Lifting hips off the bench. Holding breath without bracing properly."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000002")!,
                name: "Dumbbell Bench Press",
                aliases: ["DB Bench Press", "Dumbbell Press"],
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps, .shoulders],
                equipment: .dumbbell,
                category: .push,
                instructions: "1. Sit on a bench holding a dumbbell in each hand, resting them on your thighs.\n2. Lie back, using your thighs to kick the dumbbells up to shoulder height.\n3. Hold them slightly wider than your chest with a neutral or pronated grip.\n4. Lower the dumbbells in a controlled arc until they are at chest level, elbows at 45–75°.\n5. Press them back up, allowing the dumbbells to travel slightly inward at the top.\n6. Squeeze your chest at the top without fully locking out your elbows.",
                tips: "The dumbbell press offers a greater range of motion than the barbell press. Keep the movement controlled — use your stabilizers. The dumbbells should nearly touch at the top.",
                commonMistakes: "Letting the dumbbells drift too wide. Going too heavy before mastering the movement. Not achieving a full stretch at the bottom."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000003")!,
                name: "Incline Barbell Bench Press",
                aliases: ["Incline Bench Press", "Incline Press"],
                primaryMuscles: [.chest],
                secondaryMuscles: [.shoulders, .triceps],
                equipment: .barbell,
                category: .push,
                instructions: "1. Set a bench to a 30–45° incline.\n2. Lie back and grip the barbell slightly wider than shoulder-width.\n3. Unrack and position the bar directly above your upper chest.\n4. Lower the bar in a controlled arc to your upper chest.\n5. Press back up explosively without locking out fully between reps.",
                tips: "A 30° incline targets the upper chest effectively without over-recruiting the anterior deltoid. Keep the angle consistent. Retract your shoulder blades.",
                commonMistakes: "Setting the incline too steep (>45°), which shifts emphasis to the shoulders. Not controlling the descent."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000004")!,
                name: "Dumbbell Fly",
                aliases: ["DB Fly", "Chest Fly", "Pec Fly"],
                primaryMuscles: [.chest],
                secondaryMuscles: [],
                equipment: .dumbbell,
                category: .isolation,
                instructions: "1. Lie flat on a bench holding a dumbbell in each hand, arms extended above your chest with a slight bend in the elbows.\n2. Lower the dumbbells in a wide arc, keeping the elbow bend constant, until you feel a deep stretch in your chest.\n3. Reverse the motion, squeezing your chest as you bring the dumbbells back together above your sternum.",
                tips: "Think of hugging a large tree. Maintain the same elbow angle throughout — this is not a press. Use a weight that allows a full, controlled stretch.",
                commonMistakes: "Straightening the elbows, turning it into a press. Going too heavy and compromising the range of motion. Letting the dumbbells drop too fast."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000005")!,
                name: "Push-Up",
                aliases: ["Press Up", "Pushup"],
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps, .shoulders, .core],
                equipment: .bodyweight,
                category: .push,
                instructions: "1. Start in a high plank with hands slightly wider than shoulder-width, fingers pointing forward.\n2. Lower your chest toward the floor by bending your elbows, keeping your body rigid as a plank.\n3. Push back up to the starting position by extending your arms.\n4. Keep your core braced and hips level throughout.",
                tips: "Squeeze your glutes and brace your core to prevent your hips from sagging. Elbows should angle back at roughly 45°, not flare straight out.",
                commonMistakes: "Sagging hips or lifting the hips too high. Only performing partial range of motion. Flaring the elbows out to 90°."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000006")!,
                name: "Cable Fly",
                aliases: ["Cable Crossover", "Pec Dec (Cable)"],
                primaryMuscles: [.chest],
                secondaryMuscles: [],
                equipment: .cable,
                category: .isolation,
                instructions: "1. Set both cable pulleys to shoulder height (for mid-chest) or high/low for different emphasis.\n2. Stand in the center, holding a handle in each hand, with a slight forward lean.\n3. Extend your arms out to your sides with a slight bend in the elbows.\n4. Bring your hands together in a hugging arc in front of your chest.\n5. Squeeze your chest at full contraction, then return slowly under control.",
                tips: "Cable flies maintain constant tension throughout the movement, unlike dumbbells. Experiment with pulley height — high cables target lower chest, low cables target upper chest.",
                commonMistakes: "Using too much weight and compromising the arc. Straightening elbows and turning it into a press."
            ),

            // MARK: Back
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000010")!,
                name: "Conventional Deadlift",
                aliases: ["Deadlift", "DL"],
                primaryMuscles: [.back, .hamstrings, .glutes],
                secondaryMuscles: [.traps, .forearms, .core],
                equipment: .barbell,
                category: .hinge,
                instructions: "1. Stand with feet hip-width apart, bar over mid-foot.\n2. Hinge at the hips and bend your knees to grip the bar just outside your legs, using double overhand or mixed grip.\n3. Drop your hips, raise your chest, and take a deep breath to brace your core.\n4. Drive through your feet to lift the bar, keeping it in contact with your legs throughout.\n5. Lock out at the top by fully extending your hips and knees simultaneously.\n6. Lower the bar under control by hinging at the hips first, then bending the knees as it passes them.",
                tips: "Think 'push the floor away' rather than 'pull the bar up'. Maintain a neutral spine throughout — do not round your lower back. Engage your lats by thinking about 'bending the bar around your legs'.",
                commonMistakes: "Rounding the lower back. Jerking the bar off the floor. Letting the bar drift away from the body. Hyperextending the lower back at lockout."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000011")!,
                name: "Barbell Row",
                aliases: ["Bent Over Row", "Bent-Over Barbell Row", "BB Row"],
                primaryMuscles: [.back, .lats],
                secondaryMuscles: [.biceps, .traps, .shoulders],
                equipment: .barbell,
                category: .pull,
                instructions: "1. Stand with feet hip-width apart, holding a barbell with a pronated grip, hands slightly wider than shoulder-width.\n2. Hinge forward at the hips until your torso is roughly parallel to the floor, keeping your back flat.\n3. Let the bar hang at arm's length.\n4. Pull the bar toward your lower chest/upper abdomen by driving your elbows back and up.\n5. Squeeze your shoulder blades at the top, then lower the bar with control.",
                tips: "Think about driving your elbows toward the ceiling, not just pulling the bar up. Keep your torso angle stable throughout the set — don't use your lower back to jerk the weight.",
                commonMistakes: "Excessive torso swing. Rounding the lower back. Pulling to the wrong point (should aim for lower chest, not hips)."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000012")!,
                name: "Pull-Up",
                aliases: ["Pull Up", "Pullup", "Overhand Pull-Up"],
                primaryMuscles: [.lats, .back],
                secondaryMuscles: [.biceps, .shoulders],
                equipment: .bodyweight,
                category: .pull,
                instructions: "1. Hang from a bar with an overhand grip, hands slightly wider than shoulder-width.\n2. Depress and retract your shoulder blades to initiate the movement.\n3. Pull your body up by driving your elbows down toward your hips until your chin clears the bar.\n4. Lower yourself with control back to a full dead hang.",
                tips: "Initiate with your lats, not your biceps. Think of driving your elbows toward your back pockets. Full range of motion — dead hang at the bottom to full chin-over-bar at the top.",
                commonMistakes: "Kipping without building base strength. Not reaching full extension at the bottom. Shrugging the shoulders at the top."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000013")!,
                name: "Chin-Up",
                aliases: ["Chinup", "Supinated Pull-Up"],
                primaryMuscles: [.lats, .biceps],
                secondaryMuscles: [.back, .shoulders],
                equipment: .bodyweight,
                category: .pull,
                instructions: "1. Hang from a bar with an underhand (supinated) grip, hands shoulder-width or narrower.\n2. Pull your body up until your chin clears the bar, leading with your chest.\n3. Lower with control to a full dead hang.",
                tips: "The supinated grip places greater emphasis on the biceps compared to pull-ups. Great for building bicep strength alongside back development.",
                commonMistakes: "Not achieving full hang at the bottom. Using excessive body swing."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000014")!,
                name: "Lat Pulldown",
                aliases: ["Cable Pulldown", "Pulldown"],
                primaryMuscles: [.lats],
                secondaryMuscles: [.biceps, .back],
                equipment: .cable,
                category: .pull,
                instructions: "1. Sit at a lat pulldown machine with your knees secured under the pad.\n2. Grip the bar slightly wider than shoulder-width with an overhand grip.\n3. Lean back slightly and pull the bar down to your upper chest by driving your elbows toward the floor.\n4. Squeeze your lats at the bottom, then return the bar with control to full arm extension.",
                tips: "Lead with your elbows, not your hands. Avoid pulling behind the neck — front pulldowns are safer and equally effective. Maintain a slight chest lean.",
                commonMistakes: "Pulling behind the neck. Using excessive body sway to pull the weight. Not achieving full arm extension at the top."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000015")!,
                name: "Seated Cable Row",
                aliases: ["Cable Row", "Seated Row", "Low Cable Row"],
                primaryMuscles: [.back, .lats],
                secondaryMuscles: [.biceps, .traps],
                equipment: .cable,
                category: .pull,
                instructions: "1. Sit at a cable row machine with your feet on the platform, knees slightly bent.\n2. Grip the handle with both hands and sit upright with a neutral spine.\n3. Pull the handle toward your lower abdomen by driving your elbows back.\n4. Squeeze your shoulder blades together at full contraction.\n5. Return the handle with control, allowing a stretch at the front.",
                tips: "Allow a slight forward lean at the start and return to upright as you pull — don't stay rigidly upright or sway excessively. The stretch at the front is valuable for lat activation.",
                commonMistakes: "Leaning back too far (turning it into a lower back exercise). Not squeezing the shoulder blades. Rounding the back."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000016")!,
                name: "Dumbbell Row",
                aliases: ["One-Arm Dumbbell Row", "Single Arm Row", "DB Row"],
                primaryMuscles: [.lats, .back],
                secondaryMuscles: [.biceps, .traps],
                equipment: .dumbbell,
                category: .pull,
                instructions: "1. Place one knee and the same-side hand on a bench for support.\n2. Hold a dumbbell in the opposite hand, arm extended toward the floor.\n3. Pull the dumbbell up toward your hip, driving your elbow as high as possible.\n4. Squeeze your lat and upper back at the top, then lower with control.",
                tips: "Think about rowing your elbow, not your hand. Keep your hips and shoulders square. Allow your shoulder blade to move freely.",
                commonMistakes: "Rotating the torso excessively. Not driving the elbow high enough. Letting the shoulder drop at the bottom."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000017")!,
                name: "Face Pull",
                aliases: ["Cable Face Pull", "Rope Face Pull"],
                primaryMuscles: [.traps, .shoulders],
                secondaryMuscles: [.back],
                equipment: .cable,
                category: .pull,
                instructions: "1. Set a cable pulley to upper-chest or head height. Attach a rope.\n2. Grab the rope with both hands in a thumbs-up position and step back.\n3. Pull the rope toward your face, separating your hands at the end so they go beside your ears.\n4. Hold briefly at peak contraction with elbows high, then return under control.",
                tips: "Keep elbows at or above shoulder height throughout. This exercise is excellent for shoulder health and posterior deltoid development.",
                commonMistakes: "Keeping elbows too low (turns it into a row). Pulling with too much weight and losing form."
            ),

            // MARK: Shoulders
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000020")!,
                name: "Barbell Overhead Press",
                aliases: ["Overhead Press", "OHP", "Military Press", "Standing Press"],
                primaryMuscles: [.shoulders],
                secondaryMuscles: [.triceps, .traps, .core],
                equipment: .barbell,
                category: .push,
                instructions: "1. Stand with feet shoulder-width apart, holding the bar in front of your shoulders with a pronated grip, elbows forward and slightly under the bar.\n2. Brace your core, squeeze your glutes, and press the bar directly overhead.\n3. Move your head slightly back to let the bar pass, then shift your head back under the bar at lockout.\n4. Lower the bar back to your shoulders under control.",
                tips: "Keep your ribs down — don't flare them by hyperextending your lower back. Press in a straight line overhead. Lock out fully overhead for full shoulder development.",
                commonMistakes: "Excessive lower back arch. Pressing the bar forward instead of straight up. Not locking out overhead."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000021")!,
                name: "Dumbbell Overhead Press",
                aliases: ["Seated Dumbbell Press", "DB Shoulder Press", "Arnold Press variant"],
                primaryMuscles: [.shoulders],
                secondaryMuscles: [.triceps],
                equipment: .dumbbell,
                category: .push,
                instructions: "1. Sit on an upright bench (or stand) holding a dumbbell in each hand at shoulder height, palms facing forward.\n2. Press both dumbbells overhead until your arms are fully extended.\n3. Lower them back to shoulder height with control.",
                tips: "Can be done seated for more stability or standing for core engagement. Avoid arching your back — keep your core braced.",
                commonMistakes: "Pressing at an angle instead of straight overhead. Letting the dumbbells drift forward."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000022")!,
                name: "Lateral Raise",
                aliases: ["Side Raise", "Dumbbell Lateral Raise", "Cable Lateral Raise"],
                primaryMuscles: [.shoulders],
                secondaryMuscles: [],
                equipment: .dumbbell,
                category: .isolation,
                instructions: "1. Stand holding a dumbbell in each hand at your sides, palms facing inward.\n2. With a slight bend in the elbows, raise the dumbbells out to your sides until they reach shoulder height.\n3. Lead with your elbows and pinkies slightly higher than thumbs (internal rotation) for optimal medial delt activation.\n4. Lower with control.",
                tips: "Use lighter weights and high reps for this isolation movement. Lean slightly forward to better target the medial deltoid. Avoid shrugging at the top.",
                commonMistakes: "Swinging the weights with momentum. Shrugging the shoulders. Going above shoulder height (reduces medial delt tension)."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000023")!,
                name: "Arnold Press",
                aliases: ["Arnold Dumbbell Press"],
                primaryMuscles: [.shoulders],
                secondaryMuscles: [.triceps],
                equipment: .dumbbell,
                category: .push,
                instructions: "1. Sit holding dumbbells in front of your shoulders at chin height, palms facing you.\n2. As you press the dumbbells overhead, rotate your palms outward so they face forward at the top.\n3. Reverse the rotation as you lower back to the start.",
                tips: "The rotation during the press targets all three deltoid heads. Perform the movement smoothly and deliberately.",
                commonMistakes: "Rushing the rotation. Not achieving full lockout overhead."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000024")!,
                name: "Reverse Fly",
                aliases: ["Bent-Over Lateral Raise", "Rear Delt Fly", "Rear Fly"],
                primaryMuscles: [.shoulders, .traps],
                secondaryMuscles: [.back],
                equipment: .dumbbell,
                category: .isolation,
                instructions: "1. Stand with feet hip-width apart, hinge forward at the hips until your torso is roughly parallel to the floor.\n2. Hold a dumbbell in each hand below your chest, elbows slightly bent.\n3. Raise both dumbbells out to your sides in a wide arc until your arms are parallel to the floor.\n4. Lower slowly back to the starting position.",
                tips: "Lead with your elbows and maintain the slight bend throughout. Focus on squeezing your rear deltoids and upper back.",
                commonMistakes: "Using momentum rather than controlled movement. Straightening the elbows."
            ),

            // MARK: Legs - Quads / Squat
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000030")!,
                name: "Barbell Back Squat",
                aliases: ["Squat", "Back Squat", "High Bar Squat", "Low Bar Squat"],
                primaryMuscles: [.quads, .glutes],
                secondaryMuscles: [.hamstrings, .core, .back],
                equipment: .barbell,
                category: .squat,
                instructions: "1. Position the barbell on your upper traps (high bar) or rear deltoids (low bar). Feet shoulder-width apart, toes slightly turned out.\n2. Brace your core, take a deep breath, and unrack.\n3. Initiate the descent by pushing your hips back and bending your knees simultaneously.\n4. Squat until your thighs are at least parallel to the floor, keeping your chest up and knees tracking over your toes.\n5. Drive through your whole foot to stand back up.",
                tips: "Keep your weight balanced across your entire foot — not just your heels or toes. Brace your core before each rep. Keep your knees in line with your toes.",
                commonMistakes: "Knee cave (valgus collapse). Heels rising off the floor. Forward lean that's excessive for bar position. Not reaching depth."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000031")!,
                name: "Leg Press",
                aliases: ["Machine Leg Press", "45 Degree Leg Press"],
                primaryMuscles: [.quads, .glutes],
                secondaryMuscles: [.hamstrings],
                equipment: .machine,
                category: .squat,
                instructions: "1. Sit in the leg press with your back flat against the pad.\n2. Place your feet shoulder-width apart in the center of the platform.\n3. Push the platform away by straightening your legs, keeping a slight bend at full extension.\n4. Lower the platform until your knees are bent at about 90° (or further if mobility allows).\n5. Press back up without locking out completely.",
                tips: "Foot placement determines emphasis: higher placement targets hamstrings/glutes; lower placement emphasizes quads. Keep your lower back pressed against the pad throughout.",
                commonMistakes: "Locking out the knees at full extension. Allowing lower back to lift off the pad. Feet too narrow causing knee stress."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000032")!,
                name: "Bulgarian Split Squat",
                aliases: ["Rear Foot Elevated Split Squat", "RFESS", "Split Squat"],
                primaryMuscles: [.quads, .glutes],
                secondaryMuscles: [.hamstrings, .core],
                equipment: .dumbbell,
                category: .squat,
                instructions: "1. Stand a stride's length in front of a bench. Place your rear foot on the bench, laces down.\n2. Hold a dumbbell in each hand (or use a barbell on your back).\n3. Lower your rear knee toward the floor by bending your front knee until your front thigh is parallel to the floor.\n4. Drive through your front heel to stand back up.",
                tips: "Your front knee should stay over your front foot. The further forward your front foot, the more glute emphasis. Closer foot position = more quad emphasis.",
                commonMistakes: "Front foot too close to the bench. Letting the front knee cave inward. Not reaching adequate depth."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000033")!,
                name: "Leg Extension",
                aliases: ["Machine Leg Extension", "Quad Extension"],
                primaryMuscles: [.quads],
                secondaryMuscles: [],
                equipment: .machine,
                category: .isolation,
                instructions: "1. Sit in the leg extension machine with the pad across your shins just above your ankles.\n2. Extend your legs by straightening your knees until your legs are fully extended.\n3. Hold briefly at the top, then lower with control.",
                tips: "Control the eccentric (lowering) phase for maximum quad stimulation. Do not use excessive weight that forces you to use momentum.",
                commonMistakes: "Kicking the weight up rather than controlled extension. Lifting hips off the seat. Using too much weight."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000034")!,
                name: "Walking Lunge",
                aliases: ["Lunge", "Dumbbell Lunge", "Forward Lunge"],
                primaryMuscles: [.quads, .glutes],
                secondaryMuscles: [.hamstrings, .core],
                equipment: .dumbbell,
                category: .squat,
                instructions: "1. Stand upright holding a dumbbell in each hand at your sides.\n2. Step forward with one leg and lower your back knee toward the floor.\n3. Your front thigh should reach parallel to the floor with your front knee over your foot.\n4. Push through your front foot to bring your back foot forward, stepping into the next lunge.\n5. Alternate legs as you walk forward.",
                tips: "Keep your torso upright throughout. Take a long enough stride to avoid your front knee traveling too far past your toes.",
                commonMistakes: "Stride too short causing forward knee travel. Torso leaning too far forward. Rushing between reps."
            ),

            // MARK: Legs - Hamstrings / Hinge
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000040")!,
                name: "Romanian Deadlift",
                aliases: ["RDL", "Straight-Leg Deadlift"],
                primaryMuscles: [.hamstrings, .glutes],
                secondaryMuscles: [.back, .forearms],
                equipment: .barbell,
                category: .hinge,
                instructions: "1. Stand holding a barbell at hip level with a shoulder-width grip.\n2. With a slight bend in the knees, hinge at your hips and push them back, lowering the bar along your legs.\n3. Keep your back flat and neutral as you lower until you feel a deep stretch in your hamstrings (typically mid-shin level or when your back starts to round).\n4. Drive your hips forward to return to standing.",
                tips: "This is a hamstring stretch exercise — go as low as your hamstring flexibility allows without rounding your back. Keep the bar close to your legs throughout.",
                commonMistakes: "Bending the knees too much (turning it into a squat). Rounding the lower back. Letting the bar drift away from the body."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000041")!,
                name: "Lying Leg Curl",
                aliases: ["Leg Curl", "Hamstring Curl", "Machine Leg Curl"],
                primaryMuscles: [.hamstrings],
                secondaryMuscles: [.calves],
                equipment: .machine,
                category: .isolation,
                instructions: "1. Lie face down on the leg curl machine with the pad just above your ankles.\n2. Curl your heels toward your glutes by bending your knees.\n3. Squeeze your hamstrings at peak contraction, then lower with control.",
                tips: "Control the eccentric phase. Point your toes slightly for greater hamstring stretch at the bottom. Do not let your hips rise off the pad.",
                commonMistakes: "Lifting the hips. Rushing through the movement. Not achieving full range of motion."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000042")!,
                name: "Hip Thrust",
                aliases: ["Barbell Hip Thrust", "Glute Bridge (loaded)", "Hip Extension"],
                primaryMuscles: [.glutes],
                secondaryMuscles: [.hamstrings, .core],
                equipment: .barbell,
                category: .hinge,
                instructions: "1. Sit with your upper back against a bench, a padded barbell resting across your hips.\n2. Plant your feet flat on the floor, hip-width apart.\n3. Drive through your heels and upper back to thrust your hips up until your body forms a straight line from shoulders to knees.\n4. Squeeze your glutes hard at the top, then lower under control.",
                tips: "At the top, your shins should be vertical (90° bend at the knee). Chin tucked to maintain a neutral spine throughout.",
                commonMistakes: "Hyperextending the lower back at the top. Feet too far or too close. Not squeezing the glutes at peak."
            ),

            // MARK: Calves
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000050")!,
                name: "Standing Calf Raise",
                aliases: ["Calf Raise", "Calf Press"],
                primaryMuscles: [.calves],
                secondaryMuscles: [],
                equipment: .machine,
                category: .isolation,
                instructions: "1. Stand on a calf raise machine or a step with just the balls of your feet on the edge.\n2. Lower your heels below the step level for a full stretch.\n3. Push up onto your toes as high as possible.\n4. Hold briefly at the top, then lower slowly.",
                tips: "Go through the full range of motion — stretch at the bottom is essential for calf growth. Three-second holds at the top are effective.",
                commonMistakes: "Not going through full range of motion. Bouncing at the bottom. Moving too quickly."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000051")!,
                name: "Seated Calf Raise",
                aliases: ["Machine Seated Calf Raise"],
                primaryMuscles: [.calves],
                secondaryMuscles: [],
                equipment: .machine,
                category: .isolation,
                instructions: "1. Sit on the seated calf raise machine with the pad resting on your lower thighs.\n2. Position the balls of your feet on the footrest with heels hanging freely.\n3. Raise your heels as high as possible, squeezing the calves at the top.\n4. Lower slowly for a full stretch.",
                tips: "The seated calf raise targets the soleus (deeper calf muscle) more than standing calf raises due to the bent knee position.",
                commonMistakes: "Not achieving a full range of motion. Moving too quickly through the movement."
            ),

            // MARK: Biceps
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000060")!,
                name: "Barbell Curl",
                aliases: ["BB Curl", "Standing Barbell Curl"],
                primaryMuscles: [.biceps],
                secondaryMuscles: [.forearms],
                equipment: .barbell,
                category: .pull,
                instructions: "1. Stand holding a barbell with a supinated (underhand) grip, hands shoulder-width apart, arms fully extended.\n2. Keeping your upper arms fixed at your sides, curl the barbell up toward your shoulders.\n3. Squeeze your biceps at the top.\n4. Lower the bar slowly back to full extension.",
                tips: "Keep your elbows pinned at your sides throughout. Avoid swinging your torso to help lift the weight. The elbow should travel slightly forward at the top for full bicep contraction.",
                commonMistakes: "Swinging the body. Moving the elbows forward from the start. Not lowering to full extension."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000061")!,
                name: "Dumbbell Curl",
                aliases: ["Alternating Dumbbell Curl", "DB Curl", "Bicep Curl"],
                primaryMuscles: [.biceps],
                secondaryMuscles: [.forearms],
                equipment: .dumbbell,
                category: .pull,
                instructions: "1. Stand holding a dumbbell in each hand at your sides, palms facing in.\n2. Curl one (or both) dumbbells up while rotating your forearm so your palm faces your shoulder at the top.\n3. Squeeze the bicep at the top, then lower with control.\n4. Alternate arms or perform simultaneously.",
                tips: "Supinate fully at the top (rotate the pinky up) to maximize bicep contraction. Keep your elbow from traveling forward until the top of the movement.",
                commonMistakes: "Not supinating the forearm. Letting the elbow drift forward at the start."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000062")!,
                name: "Hammer Curl",
                aliases: ["Neutral Grip Curl", "DB Hammer Curl"],
                primaryMuscles: [.biceps, .forearms],
                secondaryMuscles: [],
                equipment: .dumbbell,
                category: .pull,
                instructions: "1. Stand holding a dumbbell in each hand at your sides, palms facing inward (neutral grip).\n2. Curl both dumbbells up with a neutral grip — do not rotate your forearms.\n3. Squeeze at the top, then lower slowly.",
                tips: "The neutral grip targets the brachialis (underneath the bicep) and brachioradialis more than a standard curl, contributing to overall arm thickness.",
                commonMistakes: "Rotating the forearm during the lift. Swinging the body."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000063")!,
                name: "Preacher Curl",
                aliases: ["Machine Preacher Curl", "Barbell Preacher Curl", "EZ Bar Preacher Curl"],
                primaryMuscles: [.biceps],
                secondaryMuscles: [],
                equipment: .ezBar,
                category: .pull,
                instructions: "1. Sit at a preacher bench and rest your upper arms on the angled pad.\n2. Hold an EZ bar or dumbbells with a supinated grip, arms nearly extended.\n3. Curl the weight up while keeping your upper arms against the pad.\n4. Lower with complete control back to near full extension.",
                tips: "The preacher curl eliminates cheating via body swing and places peak tension on the lower bicep. Do not hyperextend your elbows at the bottom.",
                commonMistakes: "Lifting the arms off the pad at the top. Hyperextending elbows at the bottom. Dropping the weight."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000064")!,
                name: "Cable Curl",
                aliases: ["Low Cable Curl", "Cable Bicep Curl"],
                primaryMuscles: [.biceps],
                secondaryMuscles: [],
                equipment: .cable,
                category: .pull,
                instructions: "1. Set a cable pulley to the lowest position and attach a straight bar or rope.\n2. Stand facing the machine, holding the handle with a supinated grip.\n3. Curl the handle up toward your shoulders while keeping your elbows at your sides.\n4. Lower with control.",
                tips: "Cables maintain constant tension throughout the movement, unlike free weights. Great for emphasizing the peak contraction.",
                commonMistakes: "Letting the elbows travel forward at the start."
            ),

            // MARK: Triceps
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000070")!,
                name: "Tricep Pushdown",
                aliases: ["Cable Pushdown", "Rope Pushdown", "Tricep Cable Pushdown"],
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                equipment: .cable,
                category: .push,
                instructions: "1. Set a cable pulley to a high position. Attach a straight bar or rope.\n2. Stand facing the machine and grip the handle with a pronated grip (bar) or thumbs-up (rope).\n3. Keep your elbows pinned at your sides and push the handle down until your arms are fully extended.\n4. Squeeze your triceps at the bottom, then return with control.",
                tips: "Keep your elbows stationary throughout — they are the pivot point. Lean forward slightly to maintain vertical forearm path. Use the rope to allow hands to separate at the bottom for full tricep extension.",
                commonMistakes: "Allowing the elbows to flare out. Leaning over too much. Not fully extending at the bottom."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000071")!,
                name: "Skull Crusher",
                aliases: ["EZ Bar Skull Crusher", "Lying Tricep Extension", "French Press"],
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                equipment: .ezBar,
                category: .push,
                instructions: "1. Lie on a flat bench holding an EZ bar (or dumbbells) with a pronated grip, arms extended above your chest.\n2. Keeping your upper arms vertical and stationary, bend your elbows to lower the bar toward your forehead (or just behind it).\n3. Extend your arms back to the starting position.",
                tips: "The long head of the tricep gets maximum stretch in this position. Control the descent — going too fast risks elbow injury. Your upper arms should not move.",
                commonMistakes: "Letting the elbows flare out wide. Moving the upper arms. Not controlling the weight."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000072")!,
                name: "Close-Grip Bench Press",
                aliases: ["Narrow Grip Bench Press", "CGBP"],
                primaryMuscles: [.triceps],
                secondaryMuscles: [.chest, .shoulders],
                equipment: .barbell,
                category: .push,
                instructions: "1. Lie on a bench and grip the barbell with hands about shoulder-width or slightly narrower.\n2. Unrack and hold the bar above your lower chest.\n3. Lower the bar to your lower chest while keeping your elbows close to your body.\n4. Press back up to full extension.",
                tips: "Shoulder-width grip is typically optimal — going too narrow places excessive stress on the wrists. Keep elbows close to your torso (not flared out).",
                commonMistakes: "Grip too narrow causing wrist pain. Flaring the elbows. Not distinguishing this from a standard bench press."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000073")!,
                name: "Overhead Tricep Extension",
                aliases: ["Overhead Tricep Press", "French Press (Standing)", "Dumbbell Overhead Extension"],
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                equipment: .dumbbell,
                category: .push,
                instructions: "1. Stand or sit holding one dumbbell with both hands (or a dumbbell in each hand) overhead.\n2. Keep your upper arms vertical beside your head.\n3. Lower the weight behind your head by bending your elbows.\n4. Extend your arms back to the starting position by squeezing your triceps.",
                tips: "This movement puts the long head of the tricep in a fully lengthened position — one of the best exercises for overall tricep mass. Keep elbows pointing forward.",
                commonMistakes: "Elbows flaring outward. Not getting the full stretch at the bottom. Lower back arching."
            ),

            // MARK: Core
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000080")!,
                name: "Plank",
                aliases: ["Front Plank", "Prone Plank"],
                primaryMuscles: [.core],
                secondaryMuscles: [.shoulders, .glutes],
                equipment: .bodyweight,
                category: .core,
                instructions: "1. Start in a forearm plank position with your elbows directly below your shoulders.\n2. Keep your body in a straight line from head to heels.\n3. Brace your core, squeeze your glutes, and hold the position.",
                tips: "Squeeze everything — glutes, quads, core — for maximum tension. Breathe consistently. Look at a spot on the floor about 12 inches in front of your hands.",
                commonMistakes: "Letting the hips sag or pike up. Holding your breath. Shrugging the shoulders."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000081")!,
                name: "Cable Crunch",
                aliases: ["Kneeling Cable Crunch", "Rope Crunch"],
                primaryMuscles: [.core],
                secondaryMuscles: [],
                equipment: .cable,
                category: .core,
                instructions: "1. Attach a rope to a high cable pulley. Kneel facing the machine and hold the rope behind your head.\n2. Round your spine to crunch your ribcage toward your pelvis.\n3. Hold briefly at the bottom, then return to the starting position with control.",
                tips: "The resistance must come from flexing your abs, not from pulling with your arms. Think about 'crunching' your ribcage to your hips, not pulling your head down.",
                commonMistakes: "Pulling with arms instead of abs. Not achieving full range of motion. Sitting back instead of crunching forward."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000082")!,
                name: "Hanging Knee Raise",
                aliases: ["Hanging Leg Raise", "HKR", "HLR"],
                primaryMuscles: [.core],
                secondaryMuscles: [.forearms, .shoulders],
                equipment: .bodyweight,
                category: .core,
                instructions: "1. Hang from a pull-up bar with an overhand grip and arms fully extended.\n2. Raise your knees toward your chest by flexing your hips and rounding your lower back.\n3. Squeeze your abs at the top, then lower your legs with control.\n4. Progress to straight leg raises for increased difficulty.",
                tips: "Avoid swinging. Posterior pelvic tilt at the top maximizes lower abdominal engagement. Control the descent.",
                commonMistakes: "Swinging with momentum. Not tilting the pelvis at the top. Letting legs drop uncontrolled."
            ),
            Exercise(
                id: UUID(uuidString: "A1000000-0000-0000-0000-000000000083")!,
                name: "Ab Rollout",
                aliases: ["Ab Wheel Rollout", "Wheel Rollout"],
                primaryMuscles: [.core],
                secondaryMuscles: [.back, .shoulders],
                equipment: .other,
                category: .core,
                instructions: "1. Kneel on the floor holding an ab wheel with both hands.\n2. Slowly roll the wheel forward, extending your body as far as you can while keeping your core braced and your back flat.\n3. Pull the wheel back to the starting position by contracting your abs.",
                tips: "This is an advanced exercise. Master the plank first. Keep your hips from dropping. Don't let your lower back arch.",
                commonMistakes: "Lower back hyperextension. Rolling out further than your strength allows. Holding breath."
            ),
        ]
    }
    // swiftlint:enable function_body_length

    // MARK: - Starter Templates

    static func makeTemplates(exercises: [Exercise]) -> [WorkoutTemplate] {
        func find(_ name: String) -> Exercise? {
            exercises.first { $0.name == name }
        }

        var templates: [WorkoutTemplate] = []

        // Push Day
        let pushDay = WorkoutTemplate(name: "Push Day – Chest / Shoulders / Triceps")
        if let benchPress = find("Barbell Bench Press") {
            let te = TemplateExercise(exercise: benchPress, order: 0, defaultSets: 4, defaultReps: 6, defaultWeight: 135, restSeconds: 180)
            te.template = pushDay
            pushDay.exercises.append(te)
        }
        if let inclinePress = find("Incline Barbell Bench Press") {
            let te = TemplateExercise(exercise: inclinePress, order: 1, defaultSets: 3, defaultReps: 8, defaultWeight: 95, restSeconds: 120)
            te.template = pushDay
            pushDay.exercises.append(te)
        }
        if let ohp = find("Barbell Overhead Press") {
            let te = TemplateExercise(exercise: ohp, order: 2, defaultSets: 3, defaultReps: 8, defaultWeight: 95, restSeconds: 120)
            te.template = pushDay
            pushDay.exercises.append(te)
        }
        if let lateralRaise = find("Lateral Raise") {
            let te = TemplateExercise(exercise: lateralRaise, order: 3, defaultSets: 3, defaultReps: 15, defaultWeight: 15, restSeconds: 60)
            te.template = pushDay
            pushDay.exercises.append(te)
        }
        if let pushdown = find("Tricep Pushdown") {
            let te = TemplateExercise(exercise: pushdown, order: 4, defaultSets: 3, defaultReps: 12, defaultWeight: 50, restSeconds: 60)
            te.template = pushDay
            pushDay.exercises.append(te)
        }
        templates.append(pushDay)

        // Pull Day
        let pullDay = WorkoutTemplate(name: "Pull Day – Back / Biceps")
        if let deadlift = find("Conventional Deadlift") {
            let te = TemplateExercise(exercise: deadlift, order: 0, defaultSets: 4, defaultReps: 5, defaultWeight: 185, restSeconds: 240)
            te.template = pullDay
            pullDay.exercises.append(te)
        }
        if let pullUp = find("Pull-Up") {
            let te = TemplateExercise(exercise: pullUp, order: 1, defaultSets: 3, defaultReps: 8, defaultWeight: 0, restSeconds: 120)
            te.template = pullDay
            pullDay.exercises.append(te)
        }
        if let row = find("Barbell Row") {
            let te = TemplateExercise(exercise: row, order: 2, defaultSets: 3, defaultReps: 8, defaultWeight: 135, restSeconds: 120)
            te.template = pullDay
            pullDay.exercises.append(te)
        }
        if let cableRow = find("Seated Cable Row") {
            let te = TemplateExercise(exercise: cableRow, order: 3, defaultSets: 3, defaultReps: 12, defaultWeight: 120, restSeconds: 90)
            te.template = pullDay
            pullDay.exercises.append(te)
        }
        if let curl = find("Barbell Curl") {
            let te = TemplateExercise(exercise: curl, order: 4, defaultSets: 3, defaultReps: 10, defaultWeight: 65, restSeconds: 60)
            te.template = pullDay
            pullDay.exercises.append(te)
        }
        if let hammer = find("Hammer Curl") {
            let te = TemplateExercise(exercise: hammer, order: 5, defaultSets: 3, defaultReps: 12, defaultWeight: 30, restSeconds: 60)
            te.template = pullDay
            pullDay.exercises.append(te)
        }
        templates.append(pullDay)

        // Leg Day
        let legDay = WorkoutTemplate(name: "Leg Day – Squat / Hinge")
        if let squat = find("Barbell Back Squat") {
            let te = TemplateExercise(exercise: squat, order: 0, defaultSets: 4, defaultReps: 5, defaultWeight: 185, restSeconds: 240)
            te.template = legDay
            legDay.exercises.append(te)
        }
        if let rdl = find("Romanian Deadlift") {
            let te = TemplateExercise(exercise: rdl, order: 1, defaultSets: 3, defaultReps: 10, defaultWeight: 135, restSeconds: 120)
            te.template = legDay
            legDay.exercises.append(te)
        }
        if let legPress = find("Leg Press") {
            let te = TemplateExercise(exercise: legPress, order: 2, defaultSets: 3, defaultReps: 12, defaultWeight: 270, restSeconds: 120)
            te.template = legDay
            legDay.exercises.append(te)
        }
        if let legCurl = find("Lying Leg Curl") {
            let te = TemplateExercise(exercise: legCurl, order: 3, defaultSets: 3, defaultReps: 12, defaultWeight: 70, restSeconds: 90)
            te.template = legDay
            legDay.exercises.append(te)
        }
        if let calfRaise = find("Standing Calf Raise") {
            let te = TemplateExercise(exercise: calfRaise, order: 4, defaultSets: 4, defaultReps: 15, defaultWeight: 90, restSeconds: 60)
            te.template = legDay
            legDay.exercises.append(te)
        }
        templates.append(legDay)

        // Upper Body
        let upperBody = WorkoutTemplate(name: "Upper Body – Full Upper")
        if let bench = find("Barbell Bench Press") {
            let te = TemplateExercise(exercise: bench, order: 0, defaultSets: 4, defaultReps: 8, defaultWeight: 135, restSeconds: 120)
            te.template = upperBody
            upperBody.exercises.append(te)
        }
        if let row = find("Barbell Row") {
            let te = TemplateExercise(exercise: row, order: 1, defaultSets: 4, defaultReps: 8, defaultWeight: 115, restSeconds: 120)
            te.template = upperBody
            upperBody.exercises.append(te)
        }
        if let ohp = find("Dumbbell Overhead Press") {
            let te = TemplateExercise(exercise: ohp, order: 2, defaultSets: 3, defaultReps: 10, defaultWeight: 40, restSeconds: 90)
            te.template = upperBody
            upperBody.exercises.append(te)
        }
        if let lat = find("Lat Pulldown") {
            let te = TemplateExercise(exercise: lat, order: 3, defaultSets: 3, defaultReps: 12, defaultWeight: 100, restSeconds: 90)
            te.template = upperBody
            upperBody.exercises.append(te)
        }
        if let curl = find("Dumbbell Curl") {
            let te = TemplateExercise(exercise: curl, order: 4, defaultSets: 3, defaultReps: 12, defaultWeight: 30, restSeconds: 60)
            te.template = upperBody
            upperBody.exercises.append(te)
        }
        if let skull = find("Skull Crusher") {
            let te = TemplateExercise(exercise: skull, order: 5, defaultSets: 3, defaultReps: 12, defaultWeight: 65, restSeconds: 60)
            te.template = upperBody
            upperBody.exercises.append(te)
        }
        templates.append(upperBody)

        return templates
    }
}
