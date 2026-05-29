//
//  AgileSelfGalleryUITests.swift
//  agile-selfUITests
//
//  Verification harness: launches seeded + onboarded and navigates to every key screen,
//  capturing a named screenshot of each so the polish work can be reviewed visually after
//  each batch. Best-effort navigation (continueAfterFailure) — a screen that can't be reached
//  is skipped, the rest still capture.
//

import XCTest

final class AgileSelfGalleryUITests: XCTestCase {

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

    /// Tap an element if it exists & becomes hittable (scrolling if needed). Returns success.
    @discardableResult
    private func tapIfPossible(_ el: XCUIElement, timeout: TimeInterval = 6, maxSwipes: Int = 6) -> Bool {
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

    /// Dismiss a presented sheet via its nav "Done" if present, else swipe down.
    private func dismissSheet() {
        let done = app.navigationBars.buttons["Done"]
        if done.exists && done.isHittable { done.tap(); return }
        let close = app.buttons["Close"]
        if close.exists && close.isHittable { close.tap(); return }
        app.swipeDown() ; app.swipeDown()
    }

    func testCaptureGallery() {
        // Home (seeded → populated)
        _ = app.tabBars.buttons["Home"].waitForExistence(timeout: 15)
        snap("home-populated")
        app.swipeUp(); app.swipeUp()
        snap("home-connection") // scrolled to reveal TODAY'S CONNECTION + health
        app.swipeDown(); app.swipeDown()

        // Insights
        if tapIfPossible(app.tabBars.buttons["Insights"]) {
            _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "TREND")).firstMatch.waitForExistence(timeout: 8)
            snap("insights")
            app.swipeUp(); app.swipeUp()
            snap("insights-connections") // scrolled to reveal CONNECTIONS
            app.swipeUp()
            snap("insights-bottom")
            app.swipeDown(); app.swipeDown(); app.swipeDown()

            // Weekly review intro → chat → summary
            if tapIfPossible(firstButton(containing: "Weekly")) {
                snap("weekly-intro")
                if tapIfPossible(firstButton(containing: "Start AI Review")) {
                    snap("weekly-chat")
                }
                dismissSheet()
            }

            // Monthly report
            if tapIfPossible(app.tabBars.buttons["Insights"]) {} // ensure on insights
            if tapIfPossible(firstButton(containing: "Monthly")) {
                _ = app.activityIndicators.firstMatch.waitForExistence(timeout: 2)
                snap("monthly")
                dismissSheet()
            }
        }

        // Profile
        if tapIfPossible(app.tabBars.buttons["Profile"]) {
            _ = app.buttons["Add action"].waitForExistence(timeout: 8)
            snap("profile")

            // Add-action sheet
            if tapIfPossible(app.buttons["Add action"]) {
                snap("add-action")
                let cancel = app.buttons["Cancel"]
                if cancel.exists { cancel.tap() }
            }

            // Settings (collapsed single row). Wait for the sheet content to actually render
            // before snapping (tapping the row alone doesn't guarantee the sheet is up yet).
            if tapIfPossible(firstButton(containing: "Settings")) {
                _ = app.staticTexts["Daily Reminder"].waitForExistence(timeout: 8)
                snap("settings")
                dismissSheet()
            }

            // Paywall via Subscription
            if tapIfPossible(firstButton(containing: "Subscription")) {
                snap("paywall")
                dismissSheet()
            }
        }
    }
}
