//
//  AgileSelfHistoryFlowUITests.swift
//  agile-selfUITests
//
//  Exercises the check-in EDIT / BACK-FILL / DELETE flow added for past-day correction:
//  Insights → History calendar → tap an empty day (back-fill) or a logged day (edit/delete).
//  Runs against the seeded + onboarded in-memory store. Best-effort navigation
//  (continueAfterFailure) so a single missed tap still captures the rest; the asserts cover
//  the new runtime code paths (date-parameterized save, streak recompute, delete) so a crash
//  in any of them fails the test.
//

import XCTest

final class AgileSelfHistoryFlowUITests: XCTestCase {

    private var app: XCUIApplication!
    private var step = 0

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["UITEST", "UITEST_ONBOARDED", "UITEST_SEED"]
        app.launch()
    }

    private func snap(_ label: String) {
        step += 1
        let att = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        att.name = String(format: "%02d-%@", step, label)
        att.lifetime = .keepAlways
        add(att)
    }

    @discardableResult
    private func tapIfPossible(_ el: XCUIElement, timeout: TimeInterval = 6, maxSwipes: Int = 10) -> Bool {
        guard el.waitForExistence(timeout: timeout) else { return false }
        var n = 0
        while !el.isHittable && n < maxSwipes { app.swipeUp(); n += 1 }
        guard el.isHittable else { return false }
        el.tap()
        return true
    }

    private func firstButton(containing text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    private func firstButton(matchingLabel predicateText: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", predicateText)).firstMatch
    }

    func testHistoryEditBackfillDeleteFlow() {
        _ = app.tabBars.buttons["Home"].waitForExistence(timeout: 15)

        // Insights → History (the link lives at the bottom of the Insights scroll view).
        XCTAssertTrue(tapIfPossible(app.tabBars.buttons["Insights"]), "Insights tab should be tappable")
        XCTAssertTrue(tapIfPossible(firstButton(containing: "History")), "History entry should be reachable")
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 8), "History calendar should appear")
        snap("history-calendar")

        // BACK-FILL: tap an empty past day → "Add Check-in", change a score, save → back to History.
        let emptyDay = firstButton(matchingLabel: "no check-in")
        if emptyDay.waitForExistence(timeout: 5), emptyDay.isHittable {
            emptyDay.tap()
            XCTAssertTrue(app.staticTexts["Add Check-in"].waitForExistence(timeout: 6),
                          "Tapping an empty day should open the back-fill editor")
            snap("history-backfill-editor")

            // Pick a high Energy face, then save (exercises the date-parameterized upsert +
            // streak recompute for a PAST day — the core new path).
            let greatEnergy = app.buttons["Energy: Great, 5 of 5"]
            if greatEnergy.waitForExistence(timeout: 3), greatEnergy.isHittable { greatEnergy.tap() }
            let save = app.buttons["Add Check-in"]
            if save.waitForExistence(timeout: 3), save.isHittable { save.tap() }
            XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 8),
                          "Saving a back-filled day should return to the History calendar")
            snap("history-after-backfill")
        }

        // EDIT + DELETE: tap a logged day → "Edit Check-in" + a Delete affordance.
        let loggedDay = firstButton(matchingLabel: "out of 5")
        if loggedDay.waitForExistence(timeout: 5), loggedDay.isHittable {
            loggedDay.tap()
            XCTAssertTrue(app.staticTexts["Edit Check-in"].waitForExistence(timeout: 6),
                          "Tapping a logged day should open the edit editor")
            XCTAssertTrue(app.buttons["Delete Check-in"].waitForExistence(timeout: 4),
                          "Edit mode should offer a delete affordance")
            snap("history-edit-editor")

            // Exercise the delete path (recompute after removal) end-to-end.
            app.buttons["Delete Check-in"].tap()
            let confirmDelete = app.buttons["Delete"]
            if confirmDelete.waitForExistence(timeout: 4), confirmDelete.isHittable {
                confirmDelete.tap()
            }
            XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 8),
                          "Deleting should return to the History calendar without crashing")
            snap("history-after-delete")
        }
    }
}
