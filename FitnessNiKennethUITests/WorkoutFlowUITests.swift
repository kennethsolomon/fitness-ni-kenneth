import XCTest

final class WorkoutFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation

    func testTabNavigation() throws {
        // Verify the three tabs exist
        let historyTab = app.tabBars.buttons["History"]
        let workoutTab = app.tabBars.buttons["Workout"]
        let exercisesTab = app.tabBars.buttons["Exercises"]

        XCTAssertTrue(historyTab.exists)
        XCTAssertTrue(workoutTab.exists)
        XCTAssertTrue(exercisesTab.exists)

        workoutTab.tap()
        exercisesTab.tap()
        historyTab.tap()
    }

    // MARK: - Start Empty Workout

    func testStartEmptyWorkout() throws {
        app.tabBars.buttons["Workout"].tap()

        let startButton = app.buttons["Start Empty Workout"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        // Confirm dialog
        let confirmButton = app.buttons["Start Workout"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        }

        // Workout should be active - look for Cancel button in toolbar
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
    }

    // MARK: - Exercise Library

    func testExerciseLibrarySearch() throws {
        app.tabBars.buttons["Exercises"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))

        searchField.tap()
        searchField.typeText("Bench")

        // Should show bench press results
        let benchPress = app.cells.staticTexts["Barbell Bench Press"]
        XCTAssertTrue(benchPress.waitForExistence(timeout: 2))
    }

    // MARK: - History Empty State

    func testHistoryEmptyState() throws {
        app.tabBars.buttons["History"].tap()

        // Either shows empty state or workout list
        let historyTitle = app.navigationBars["History"].staticTexts["History"]
        XCTAssertTrue(historyTitle.waitForExistence(timeout: 3))
    }
}
