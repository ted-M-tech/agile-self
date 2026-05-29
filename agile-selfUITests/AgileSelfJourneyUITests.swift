//
//  AgileSelfJourneyUITests.swift
//  agile-selfUITests
//
//  One continuous user journey — launch → onboarding (name, how-it-works, permissions) →
//  first check-in → confirmation → populated Home → Profile → Insights — capturing a named
//  screenshot at every step so the flow can be reviewed visually for UI/UX, not just pass/fail.
//
//  Launched with just ["UITEST"] → fresh onboarding on an in-memory store (no disk pollution).
//  Permission toggles are turned off before "Continue" to avoid system dialogs blocking the run.
//

import XCTest

final class AgileSelfJourneyUITests: XCTestCase {

    private var app: XCUIApplication!
    private var step = 0

    override func setUpWithError() throws {
        continueAfterFailure = true // keep walking the journey even if one assert is soft
        app = XCUIApplication()
        app.launchArguments = ["UITEST"] // fresh → onboarding
        app.launch()
    }

    /// Attach a named screenshot of the current screen (kept even on success).
    private func snap(_ label: String) {
        step += 1
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = String(format: "%02d-%@", step, label)
        att.lifetime = .keepAlways
        add(att)
    }

    private func scrollAndTap(_ element: XCUIElement, max: Int = 8) {
        _ = element.waitForExistence(timeout: 10)
        var n = 0
        while !element.isHittable && n < max { app.swipeUp(); n += 1 }
        if element.isHittable { element.tap() }
        else { element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
    }

    func testFullJourney() {
        // 1. Welcome
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 15))
        snap("welcome")
        app.buttons["Get Started"].tap()

        // 2. Name
        XCTAssertTrue(app.staticTexts["What's your name?"].waitForExistence(timeout: 5))
        snap("name-empty")
        let nameField = app.textFields.firstMatch
        nameField.tap()
        // Trailing return submits the field (.onSubmit), which saves the name and advances
        // to How It Works — same as tapping Continue, so no extra Continue tap here.
        nameField.typeText("Tetsuya\n")
        snap("name-filled")

        // 3. How It Works
        XCTAssertTrue(app.staticTexts["How It Works"].waitForExistence(timeout: 5))
        snap("how-it-works")
        app.buttons["Continue"].tap()

        // 4. Permissions — turn toggles OFF so no system dialog blocks the run.
        XCTAssertTrue(app.staticTexts["Permissions"].waitForExistence(timeout: 5))
        for i in 0..<min(app.switches.count, 4) {
            let sw = app.switches.element(boundBy: i)
            if (sw.value as? String) == "1" { sw.tap() }
        }
        snap("permissions")
        app.buttons["Continue"].tap()

        // 5. Ready → complete onboarding via "Skip for now".
        // "Start First Check-in" deep-links straight into the check-in cover (it would cover
        // the first-run hero this test asserts next), so the skip path lands us on the hero,
        // which the subsequent steps explicitly open the check-in from.
        XCTAssertTrue(app.staticTexts["Ready to Start?"].waitForExistence(timeout: 5))
        snap("ready")
        app.buttons["Skip for now"].tap()

        // 6. Home — first-run hero (no check-ins yet)
        XCTAssertTrue(app.staticTexts["Let's take your first check-in"].waitForExistence(timeout: 10))
        snap("home-first-run-hero")

        // 7. Open check-in from the hero CTA
        scrollAndTap(app.buttons["Start my first check-in"])
        XCTAssertTrue(app.staticTexts["How are you doing today?"].waitForExistence(timeout: 5))
        snap("checkin-form")

        // 8. Save (default scores) → confirmation
        scrollAndTap(app.buttons["Save Check-in"])
        XCTAssertTrue(app.staticTexts["Composite Score"].waitForExistence(timeout: 8))
        snap("checkin-confirmation")

        // 9. Populated Home (after the confirmation auto-dismisses)
        let populated = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Today's score is")).firstMatch
        XCTAssertTrue(populated.waitForExistence(timeout: 12))
        snap("home-populated")

        // 10. Profile
        app.tabBars.buttons["Profile"].tap()
        _ = app.buttons["Add action"].waitForExistence(timeout: 10)
        snap("profile")

        // 11. Insights (now has 1 check-in)
        app.tabBars.buttons["Insights"].tap()
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "TREND")).firstMatch.waitForExistence(timeout: 10)
        snap("insights")
    }
}
