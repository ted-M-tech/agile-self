//
//  AgileSelfM2FlowUITests.swift
//  agile-selfUITests
//
//  Automated coverage of the M2 in-app core journey (onboarding, Home empty/populated,
//  check-in upsert, actions add/delete, Insights empty). Runs on the SIMULATOR — the logic
//  these assert is deterministic and device-independent, so no physical device is needed.
//
//  Uses the app's UI-test launch seam (agile_selfApp.swift):
//    "UITEST"            → ephemeral in-memory store (fresh empty state every run)
//    "UITEST_ONBOARDED"  → start on MainTabView (skip onboarding); otherwise start at onboarding
//
//  Device-only behaviors (real HealthKit values, Apple-Intelligence LLM prose, the home-screen
//  widget render) are intentionally NOT covered here — they are confirmed via os_log on device.
//
//  Selector notes (controls override visible text with accessibilityLabel):
//    - Home CTA label is "Log today's score"; populated state is a button "Today's score is …".
//    - The action input is a vertical TextField, exposed to XCUITest as a textView, label "Action text".
//

import XCTest

final class AgileSelfM2FlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launch(_ extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST"] + extraArgs
        app.launch()
        return app
    }

    /// Scrolls up to bring `element` into the hittable region, then taps it. Falls back to a
    /// coordinate tap if the element is on-screen but flagged non-hittable.
    private func scrollAndTap(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), "element never appeared: \(element)")
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    /// A vertical SwiftUI TextField shows up as a textView in XCUITest; single-line as a textField.
    private func textInput(label: String, in app: XCUIApplication) -> XCUIElement {
        let textView = app.textViews[label]
        if textView.waitForExistence(timeout: 5) { return textView }
        return app.textFields[label]
    }

    // MARK: - Onboarding

    /// Welcome → Name → How It Works → Permissions. Stops before "Continue" on Permissions,
    /// which would trigger the system Notifications dialog.
    func testOnboardingNavigatesToPermissions() {
        let app = launch() // fresh → onboarding

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 15), "Welcome screen CTA missing")
        getStarted.tap()

        XCTAssertTrue(app.staticTexts["What's your name?"].waitForExistence(timeout: 5), "Name screen missing")
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Name field missing")
        nameField.tap()
        // Trailing newline submits the field (.submitLabel(.continue) → .onSubmit), which
        // saves the name AND advances to How It Works — equivalent to tapping Continue.
        nameField.typeText("Tester\n")

        XCTAssertTrue(app.staticTexts["How It Works"].waitForExistence(timeout: 5), "How It Works screen missing")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["Permissions"].waitForExistence(timeout: 5), "Permissions screen missing")
    }

    // MARK: - Home empty state

    func testHomeEmptyState() {
        let app = launch(["UITEST_ONBOARDED"])

        // First-run hero replaces the empty dashboard skeleton entirely.
        XCTAssertTrue(app.staticTexts["Let's take your first check-in"].waitForExistence(timeout: 15), "First-run hero missing")
        XCTAssertTrue(app.buttons["Start my first check-in"].exists, "Hero CTA missing")
        // The empty chart / placeholders must NOT be shown to a brand-new user.
        XCTAssertFalse(app.staticTexts["No scores yet"].exists, "Empty trend chart should be hidden in first-run hero")
    }

    // MARK: - Check-in → confirmation → populated Home

    func testCheckInPopulatesHome() {
        let app = launch(["UITEST_ONBOARDED"])

        // Fresh account → first-run hero. Open the check-in from the hero CTA.
        XCTAssertTrue(app.staticTexts["Let's take your first check-in"].waitForExistence(timeout: 15), "Home did not load (hero)")

        scrollAndTap(app.buttons["Start my first check-in"], in: app)

        XCTAssertTrue(app.staticTexts["How are you doing today?"].waitForExistence(timeout: 5), "Check-in sheet missing")

        // Default scores (all 5) are fine — we test save/confirmation/populate, not the picker.
        scrollAndTap(app.buttons["Save Check-in"], in: app)

        // Confirmation overlay.
        XCTAssertTrue(app.staticTexts["Composite Score"].waitForExistence(timeout: 8), "Confirmation overlay missing")

        // After the overlay auto-dismisses, the CTA becomes the populated summary button whose
        // accessibilityLabel begins "Today's score is …".
        let populated = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Today's score is")).firstMatch
        XCTAssertTrue(populated.waitForExistence(timeout: 12), "Home did not show populated Today's score summary")
    }

    // MARK: - Actions: add then delete (long-press context menu)

    func testAddAndDeleteAction() {
        let app = launch(["UITEST_ONBOARDED"])

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 15), "Profile tab missing")
        profileTab.tap()

        // Wait on the toolbar "+" (accessibilityLabel "Add action") rather than the nav-bar title.
        let addButton = app.buttons["Add action"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "Profile / Add action button missing")
        addButton.tap()

        // Vertical TextField → textView in XCUITest; label is "Action text".
        let field = textInput(label: "Action text", in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Action text field missing")
        field.tap()
        field.typeText("Test action XYZ")
        app.buttons["Add"].tap()

        let row = app.staticTexts["Test action XYZ"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Added action row missing")

        // Delete is a long-press context menu (NOT swipe).
        row.press(forDuration: 1.2)
        let deleteItem = app.buttons["Delete"]
        XCTAssertTrue(deleteItem.waitForExistence(timeout: 5), "Delete context-menu item missing")
        deleteItem.tap()

        XCTAssertFalse(app.staticTexts["Test action XYZ"].waitForExistence(timeout: 3), "Action was not deleted")
    }

    // MARK: - Insights empty state

    func testInsightsEmptyState() {
        let app = launch(["UITEST_ONBOARDED"])

        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 15), "Insights tab missing")
        insightsTab.tap()

        XCTAssertTrue(app.staticTexts["No Check-ins Yet"].waitForExistence(timeout: 10), "Insights empty state missing")
    }
}
