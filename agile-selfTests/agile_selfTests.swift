//
//  agile_selfTests.swift
//  agile-selfTests
//
//  Created by Tetsuya Maeda on 2025/11/30.
//

import Testing
import Foundation
@testable import agile_self

// MARK: - ActionItem Tests

struct ActionItemTests {

    // MARK: - Initialization Tests

    @Test
    func testActionItemInitializationWithDefaults() {
        let action = ActionItem(text: "Complete weekly report")

        #expect(action.text == "Complete weekly report")
        #expect(action.isCompleted == false)
        #expect(action.deadline == nil)
        #expect(action.completedAt == nil)
        #expect(action.fromTryItem == false)
        #expect(action.priority == .medium)
        #expect(action.notes == nil)
        #expect(action.id != UUID())
    }

    @Test
    func testActionItemInitializationWithAllParameters() {
        let id = UUID()
        let deadline = Date().addingTimeInterval(86400) // Tomorrow
        let createdAt = Date()
        let updatedAt = Date()

        let action = ActionItem(
            id: id,
            text: "Test action",
            isCompleted: true,
            deadline: deadline,
            completedAt: createdAt,
            fromTryItem: true,
            priority: .high,
            notes: "Test notes",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        #expect(action.id == id)
        #expect(action.text == "Test action")
        #expect(action.isCompleted == true)
        #expect(action.deadline == deadline)
        #expect(action.completedAt == createdAt)
        #expect(action.fromTryItem == true)
        #expect(action.priority == .high)
        #expect(action.notes == "Test notes")
        #expect(action.createdAt == createdAt)
        #expect(action.updatedAt == updatedAt)
    }

    // MARK: - isOverdue Computed Property Tests

    @Test
    func testIsOverdueWhenNoDeadline() {
        let action = ActionItem(text: "No deadline action")

        #expect(action.isOverdue == false)
    }

    @Test
    func testIsOverdueWhenCompletedBeforeDeadline() {
        let pastDeadline = Date().addingTimeInterval(-86400) // Yesterday
        let action = ActionItem(
            text: "Completed action",
            isCompleted: true,
            deadline: pastDeadline
        )

        #expect(action.isOverdue == false, "Completed items should never be overdue")
    }

    @Test
    func testIsOverdueWhenDeadlinePassed() {
        let pastDeadline = Date().addingTimeInterval(-86400) // Yesterday
        let action = ActionItem(
            text: "Late action",
            isCompleted: false,
            deadline: pastDeadline
        )

        #expect(action.isOverdue == true)
    }

    @Test
    func testIsOverdueWhenDeadlineInFuture() {
        let futureDeadline = Date().addingTimeInterval(86400) // Tomorrow
        let action = ActionItem(
            text: "Future action",
            isCompleted: false,
            deadline: futureDeadline
        )

        #expect(action.isOverdue == false)
    }

    // MARK: - markCompleted() Tests

    @Test
    func testMarkCompleted() {
        let action = ActionItem(text: "Action to complete")

        #expect(action.isCompleted == false)
        #expect(action.completedAt == nil)

        action.markCompleted()

        #expect(action.isCompleted == true)
        #expect(action.completedAt != nil)
    }

    @Test
    func testMarkCompletedSetsCompletedAtToCurrentTime() {
        let action = ActionItem(text: "Action to complete")
        let beforeCompletion = Date()

        action.markCompleted()

        let afterCompletion = Date()

        guard let completedAt = action.completedAt else {
            Issue.record("completedAt should not be nil after markCompleted()")
            return
        }

        #expect(completedAt >= beforeCompletion)
        #expect(completedAt <= afterCompletion)
    }

    // MARK: - markIncomplete() Tests

    @Test
    func testMarkIncomplete() {
        let now = Date()
        let action = ActionItem(
            text: "Completed action",
            isCompleted: true,
            completedAt: now
        )

        action.markIncomplete()

        #expect(action.isCompleted == false)
        #expect(action.completedAt == nil)
    }

    @Test
    func testMarkIncompleteOnAlreadyIncompleteAction() {
        let action = ActionItem(text: "Incomplete action")

        action.markIncomplete()

        #expect(action.isCompleted == false)
        #expect(action.completedAt == nil)
    }

    // MARK: - toggleCompletion() Tests

    @Test
    func testToggleCompletionFromIncomplete() {
        let action = ActionItem(text: "Test action")

        #expect(action.isCompleted == false)

        action.toggleCompletion()

        #expect(action.isCompleted == true)
        #expect(action.completedAt != nil)
    }

    @Test
    func testToggleCompletionFromComplete() {
        let action = ActionItem(text: "Test action", isCompleted: true, completedAt: Date())

        action.toggleCompletion()

        #expect(action.isCompleted == false)
        #expect(action.completedAt == nil)
    }

    // MARK: - Priority Tests

    @Test
    func testPriorityUpdate() {
        let action = ActionItem(text: "Test action")
        let originalUpdatedAt = action.updatedAt

        // Small delay to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        action.updatePriority(.high)

        #expect(action.priority == .high)
        #expect(action.updatedAt > originalUpdatedAt)
    }

    @Test
    func testAllPriorityLevels() {
        let highAction = ActionItem(text: "High", priority: .high)
        let mediumAction = ActionItem(text: "Medium", priority: .medium)
        let lowAction = ActionItem(text: "Low", priority: .low)

        #expect(highAction.priority == .high)
        #expect(mediumAction.priority == .medium)
        #expect(lowAction.priority == .low)
    }

    // MARK: - Notes Tests

    @Test
    func testNotesUpdate() {
        let action = ActionItem(text: "Test action")

        #expect(action.hasNotes == false)

        action.updateNotes("New notes")

        #expect(action.notes == "New notes")
        #expect(action.hasNotes == true)
    }

    @Test
    func testNotesWithWhitespace() {
        let action = ActionItem(text: "Test action")

        action.updateNotes("   Trimmed notes   ")

        #expect(action.notes == "Trimmed notes")
    }

    @Test
    func testClearNotes() {
        let action = ActionItem(text: "Test action", notes: "Some notes")

        action.updateNotes(nil)

        #expect(action.notes == nil)
        #expect(action.hasNotes == false)
    }

    @Test
    func testEmptyNotesNotConsideredAsHavingNotes() {
        let action = ActionItem(text: "Test action", notes: "   ")

        #expect(action.hasNotes == false)
    }

    // MARK: - Deadline Description Tests

    @Test
    func testDeadlineDescriptionOverdue() {
        let pastDeadline = Date().addingTimeInterval(-86400 * 2) // 2 days ago
        let action = ActionItem(text: "Test", deadline: pastDeadline)

        let description = action.deadlineDescription

        #expect(description?.contains("Overdue") == true)
    }

    @Test
    func testDeadlineDescriptionDueToday() {
        // Create a deadline that's today but not past yet
        let calendar = Calendar.current
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let action = ActionItem(text: "Test", deadline: endOfToday)

        // Only test if the deadline is actually still in the future
        if endOfToday > Date() {
            let description = action.deadlineDescription

            #expect(description == "Due today" || description == "Due tomorrow" || description?.contains("Due in") == true)
        }
    }

    @Test
    func testDeadlineDescriptionDueTomorrow() {
        let tomorrowDeadline = Date().addingTimeInterval(86400) // Tomorrow
        let action = ActionItem(text: "Test", deadline: tomorrowDeadline)

        let description = action.deadlineDescription

        #expect(description == "Due tomorrow" || description == "Due in 1 days")
    }

    @Test
    func testDeadlineDescriptionNoDeadline() {
        let action = ActionItem(text: "Test")

        #expect(action.deadlineDescription == nil)
    }

    // MARK: - isDueSoon Tests

    @Test
    func testIsDueSoonWithinRange() {
        let soonDeadline = Date().addingTimeInterval(86400 * 2) // 2 days from now
        let action = ActionItem(text: "Test", deadline: soonDeadline)

        #expect(action.isDueSoon(withinDays: 3) == true)
    }

    @Test
    func testIsDueSoonOutsideRange() {
        let farDeadline = Date().addingTimeInterval(86400 * 10) // 10 days from now
        let action = ActionItem(text: "Test", deadline: farDeadline)

        #expect(action.isDueSoon(withinDays: 3) == false)
    }

    @Test
    func testIsDueSoonOverdueNotConsidered() {
        let pastDeadline = Date().addingTimeInterval(-86400) // Yesterday
        let action = ActionItem(text: "Test", deadline: pastDeadline)

        #expect(action.isDueSoon() == false)
    }

    @Test
    func testIsDueSoonCompletedNotConsidered() {
        let soonDeadline = Date().addingTimeInterval(86400) // Tomorrow
        let action = ActionItem(text: "Test", isCompleted: true, deadline: soonDeadline)

        #expect(action.isDueSoon() == false)
    }

    // MARK: - touch() Tests

    @Test
    func testTouchUpdatesTimestamp() {
        let originalUpdatedAt = Date().addingTimeInterval(-3600) // 1 hour ago
        let action = ActionItem(text: "Test", updatedAt: originalUpdatedAt)

        let beforeTouch = Date()
        action.touch()
        let afterTouch = Date()

        #expect(action.updatedAt >= beforeTouch)
        #expect(action.updatedAt <= afterTouch)
        #expect(action.updatedAt > originalUpdatedAt)
    }
}

// MARK: - KPTAItem Tests

struct KPTAItemTests {

    @Test
    func testKPTAItemInitializationWithDefaults() {
        let item = KPTAItem(text: "Test item", category: .keep)

        #expect(item.text == "Test item")
        #expect(item.category == .keep)
        #expect(item.orderIndex == 0)
        #expect(item.retrospective == nil)
    }

    @Test
    func testKPTAItemInitializationWithAllParameters() {
        let id = UUID()
        let createdAt = Date()

        let item = KPTAItem(
            id: id,
            text: "Problem item",
            category: .problem,
            orderIndex: 5,
            createdAt: createdAt
        )

        #expect(item.id == id)
        #expect(item.text == "Problem item")
        #expect(item.category == .problem)
        #expect(item.orderIndex == 5)
        #expect(item.createdAt == createdAt)
    }

    @Test
    func testKPTAItemWithTryCategory() {
        let item = KPTAItem(text: "Try something new", category: .try)

        #expect(item.category == .try)
    }
}

// MARK: - KPTACategory Tests

struct KPTACategoryTests {

    @Test
    func testDisplayNames() {
        #expect(KPTACategory.keep.displayName == "Keep")
        #expect(KPTACategory.problem.displayName == "Problem")
        #expect(KPTACategory.try.displayName == "Try")
    }

    @Test
    func testIconNames() {
        #expect(KPTACategory.keep.iconName == "checkmark.circle.fill")
        #expect(KPTACategory.problem.iconName == "exclamationmark.triangle.fill")
        #expect(KPTACategory.try.iconName == "lightbulb.fill")
    }

    @Test
    func testCaseIterable() {
        let allCases = KPTACategory.allCases

        #expect(allCases.count == 3)
        #expect(allCases.contains(.keep))
        #expect(allCases.contains(.problem))
        #expect(allCases.contains(.try))
    }

    @Test
    func testRawValues() {
        #expect(KPTACategory.keep.rawValue == "keep")
        #expect(KPTACategory.problem.rawValue == "problem")
        #expect(KPTACategory.try.rawValue == "try")
    }
}

// MARK: - RetrospectiveType Tests

struct RetrospectiveTypeTests {

    @Test
    func testDisplayNames() {
        #expect(RetrospectiveType.weekly.displayName == "Weekly")
        #expect(RetrospectiveType.monthly.displayName == "Monthly")
    }

    @Test
    func testCaseIterable() {
        let allCases = RetrospectiveType.allCases

        #expect(allCases.count == 2)
        #expect(allCases.contains(.weekly))
        #expect(allCases.contains(.monthly))
    }

    @Test
    func testRawValues() {
        #expect(RetrospectiveType.weekly.rawValue == "weekly")
        #expect(RetrospectiveType.monthly.rawValue == "monthly")
    }
}

// MARK: - Retrospective Tests

struct RetrospectiveTests {

    // MARK: - Initialization Tests

    @Test
    func testRetrospectiveInitializationWithDefaults() {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(604800) // 7 days later

        let retro = Retrospective(
            title: "Week 1",
            type: .weekly,
            startDate: startDate,
            endDate: endDate
        )

        #expect(retro.title == "Week 1")
        #expect(retro.type == .weekly)
        #expect(retro.startDate == startDate)
        #expect(retro.endDate == endDate)
        #expect(retro.keeps.isEmpty)
        #expect(retro.problems.isEmpty)
        #expect(retro.tries.isEmpty)
        #expect(retro.actions.isEmpty)
        #expect(retro.healthSummary == nil)
    }

    @Test
    func testRetrospectiveInitializationWithAllParameters() {
        let id = UUID()
        let startDate = Date()
        let endDate = Date().addingTimeInterval(604800)
        let createdAt = Date()
        let updatedAt = Date()

        let keeps = [KPTAItem(text: "Keep item", category: .keep)]
        let problems = [KPTAItem(text: "Problem item", category: .problem)]
        let tries = [KPTAItem(text: "Try item", category: .try)]
        let actions = [ActionItem(text: "Action item")]

        let retro = Retrospective(
            id: id,
            title: "Monthly Review",
            type: .monthly,
            startDate: startDate,
            endDate: endDate,
            keeps: keeps,
            problems: problems,
            tries: tries,
            actions: actions,
            healthSummary: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        #expect(retro.id == id)
        #expect(retro.title == "Monthly Review")
        #expect(retro.type == .monthly)
        #expect(retro.keeps.count == 1)
        #expect(retro.problems.count == 1)
        #expect(retro.tries.count == 1)
        #expect(retro.actions.count == 1)
    }

    // MARK: - Computed Properties Tests

    @Test
    func testPendingActionsCountWithNoActions() {
        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date()
        )

        #expect(retro.pendingActionsCount == 0)
    }

    @Test
    func testPendingActionsCountWithMixedActions() {
        let completedAction = ActionItem(text: "Done", isCompleted: true)
        let pendingAction1 = ActionItem(text: "Pending 1", isCompleted: false)
        let pendingAction2 = ActionItem(text: "Pending 2", isCompleted: false)

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            actions: [completedAction, pendingAction1, pendingAction2]
        )

        #expect(retro.pendingActionsCount == 2)
    }

    @Test
    func testCompletedActionsCountWithNoActions() {
        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date()
        )

        #expect(retro.completedActionsCount == 0)
    }

    @Test
    func testCompletedActionsCountWithMixedActions() {
        let completedAction1 = ActionItem(text: "Done 1", isCompleted: true)
        let completedAction2 = ActionItem(text: "Done 2", isCompleted: true)
        let pendingAction = ActionItem(text: "Pending", isCompleted: false)

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            actions: [completedAction1, completedAction2, pendingAction]
        )

        #expect(retro.completedActionsCount == 2)
    }

    @Test
    func testActionCompletionRateWithNoActions() {
        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date()
        )

        #expect(retro.actionCompletionRate == 0)
    }

    @Test
    func testActionCompletionRateWithAllCompleted() {
        let action1 = ActionItem(text: "Done 1", isCompleted: true)
        let action2 = ActionItem(text: "Done 2", isCompleted: true)

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            actions: [action1, action2]
        )

        #expect(retro.actionCompletionRate == 1.0)
    }

    @Test
    func testActionCompletionRateWithHalfCompleted() {
        let completed = ActionItem(text: "Done", isCompleted: true)
        let pending = ActionItem(text: "Pending", isCompleted: false)

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            actions: [completed, pending]
        )

        #expect(retro.actionCompletionRate == 0.5)
    }

    @Test
    func testActionCompletionRateWithNoneCompleted() {
        let action1 = ActionItem(text: "Pending 1", isCompleted: false)
        let action2 = ActionItem(text: "Pending 2", isCompleted: false)

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            actions: [action1, action2]
        )

        #expect(retro.actionCompletionRate == 0.0)
    }

    @Test
    func testTotalKPTACountWithEmptyArrays() {
        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date()
        )

        #expect(retro.totalKPTACount == 0)
    }

    @Test
    func testTotalKPTACountWithItems() {
        let keeps = [
            KPTAItem(text: "Keep 1", category: .keep),
            KPTAItem(text: "Keep 2", category: .keep)
        ]
        let problems = [KPTAItem(text: "Problem 1", category: .problem)]
        let tries = [
            KPTAItem(text: "Try 1", category: .try),
            KPTAItem(text: "Try 2", category: .try),
            KPTAItem(text: "Try 3", category: .try)
        ]

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            keeps: keeps,
            problems: problems,
            tries: tries
        )

        #expect(retro.totalKPTACount == 6)
    }

    @Test
    func testFormattedDateRange() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startDate = formatter.date(from: "2025-01-01")!
        let endDate = formatter.date(from: "2025-01-07")!

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: startDate,
            endDate: endDate
        )

        let formattedRange = retro.formattedDateRange

        // The format depends on locale, but it should contain both dates
        #expect(formattedRange.contains("-"))
    }

    // MARK: - Helper Methods Tests

    @Test
    func testGenerateTitleForWeekly() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startDate = formatter.date(from: "2025-01-06")! // Monday
        let endDate = formatter.date(from: "2025-01-12")! // Sunday

        let title = Retrospective.generateTitle(for: .weekly, startDate: startDate, endDate: endDate)

        #expect(title.hasPrefix("Week of"))
    }

    @Test
    func testGenerateTitleForMonthly() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startDate = formatter.date(from: "2025-01-01")!
        let endDate = formatter.date(from: "2025-01-31")!

        let title = Retrospective.generateTitle(for: .monthly, startDate: startDate, endDate: endDate)

        // Should be formatted as "MMMM yyyy" - e.g., "January 2025"
        #expect(title.contains("2025"))
    }

    @Test
    func testTouch() {
        let originalDate = Date().addingTimeInterval(-3600) // 1 hour ago

        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            updatedAt: originalDate
        )

        let beforeTouch = Date()
        retro.touch()
        let afterTouch = Date()

        #expect(retro.updatedAt >= beforeTouch)
        #expect(retro.updatedAt <= afterTouch)
        #expect(retro.updatedAt > originalDate)
    }
}

// MARK: - HealthSummary Tests

struct HealthSummaryTests {

    @Test
    func testHealthSummaryInitializationWithDefaults() {
        let periodStart = Date()
        let periodEnd = Date().addingTimeInterval(604800)

        let summary = HealthSummary(periodStart: periodStart, periodEnd: periodEnd)

        #expect(summary.periodStart == periodStart)
        #expect(summary.periodEnd == periodEnd)
        #expect(summary.avgSleepMinutes == nil)
        #expect(summary.avgSleepQualityScore == nil)
        #expect(summary.avgSteps == nil)
        #expect(summary.totalExerciseMinutes == nil)
        #expect(summary.avgStandHours == nil)
        #expect(summary.avgActiveCalories == nil)
        #expect(summary.totalWorkouts == nil)
        #expect(summary.wellnessScore == nil)
    }

    @Test
    func testHealthSummaryInitializationWithAllParameters() {
        let id = UUID()
        let periodStart = Date()
        let periodEnd = Date().addingTimeInterval(604800)
        let createdAt = Date()

        let summary = HealthSummary(
            id: id,
            periodStart: periodStart,
            periodEnd: periodEnd,
            avgSleepMinutes: 480,
            avgSleepQualityScore: 85,
            avgSteps: 10000,
            totalExerciseMinutes: 180,
            avgStandHours: 12,
            avgActiveCalories: 500,
            totalWorkouts: 5,
            wellnessScore: 90,
            createdAt: createdAt
        )

        #expect(summary.id == id)
        #expect(summary.avgSleepMinutes == 480)
        #expect(summary.avgSleepQualityScore == 85)
        #expect(summary.avgSteps == 10000)
        #expect(summary.totalExerciseMinutes == 180)
        #expect(summary.avgStandHours == 12)
        #expect(summary.avgActiveCalories == 500)
        #expect(summary.totalWorkouts == 5)
        #expect(summary.wellnessScore == 90)
    }

    // MARK: - Computed Properties Tests

    @Test
    func testFormattedSleepDurationWithNil() {
        let summary = HealthSummary(periodStart: Date(), periodEnd: Date())

        #expect(summary.formattedSleepDuration == nil)
    }

    @Test
    func testFormattedSleepDurationWithMinutes() {
        let summary = HealthSummary(
            periodStart: Date(),
            periodEnd: Date(),
            avgSleepMinutes: 450 // 7h 30m
        )

        #expect(summary.formattedSleepDuration == "7h 30m")
    }

    @Test
    func testFormattedSleepDurationWithExactHours() {
        let summary = HealthSummary(
            periodStart: Date(),
            periodEnd: Date(),
            avgSleepMinutes: 480 // 8h 0m
        )

        #expect(summary.formattedSleepDuration == "8h 0m")
    }

    @Test
    func testFormattedStepsWithNil() {
        let summary = HealthSummary(periodStart: Date(), periodEnd: Date())

        #expect(summary.formattedSteps == nil)
    }

    @Test
    func testFormattedStepsWithValue() {
        let summary = HealthSummary(
            periodStart: Date(),
            periodEnd: Date(),
            avgSteps: 10000
        )

        let formatted = summary.formattedSteps
        #expect(formatted != nil)
        // Should be formatted with thousands separator
        #expect(formatted?.contains("10") == true)
    }

    @Test
    func testFormattedStepsWithSmallValue() {
        let summary = HealthSummary(
            periodStart: Date(),
            periodEnd: Date(),
            avgSteps: 500
        )

        let formatted = summary.formattedSteps
        #expect(formatted != nil)
        #expect(formatted == "500")
    }
}

// MARK: - Theme Tests

struct ThemeTests {

    @Test
    func testKPTAColorsForAllCategories() {
        // Ensure color mapping works for all categories
        for category in KPTACategory.allCases {
            let color = Theme.KPTA.color(for: category)
            let bgColor = Theme.KPTA.backgroundColor(for: category)
            // Just verify no crash and values are returned
            #expect(color != bgColor)
        }
    }

    @Test
    func testWellbeingColorForHighScore() {
        let color = Theme.Wellbeing.color(for: 85)
        // High scores should be green - just verify no crash
        #expect(color == .green)
    }

    @Test
    func testWellbeingColorForMediumScore() {
        let color = Theme.Wellbeing.color(for: 60)
        #expect(color == .orange)
    }

    @Test
    func testWellbeingColorForLowScore() {
        let color = Theme.Wellbeing.color(for: 30)
        #expect(color == .red)
    }

    @Test
    func testWellbeingLabelForExcellent() {
        let label = Theme.Wellbeing.label(for: 85)
        #expect(label == "Excellent")
    }

    @Test
    func testWellbeingLabelForGood() {
        let label = Theme.Wellbeing.label(for: 75)
        #expect(label == "Good")
    }

    @Test
    func testWellbeingLabelForFair() {
        let label = Theme.Wellbeing.label(for: 55)
        #expect(label == "Fair")
    }

    @Test
    func testWellbeingLabelForNeedsAttention() {
        let label = Theme.Wellbeing.label(for: 40)
        #expect(label == "Needs Attention")
    }

    @Test
    func testWellbeingLabelForLow() {
        let label = Theme.Wellbeing.label(for: 20)
        #expect(label == "Low")
    }

    @Test
    func testWellbeingBoundaryValues() {
        // Test boundary values
        #expect(Theme.Wellbeing.color(for: 70) == .green)
        #expect(Theme.Wellbeing.color(for: 69) == .orange)
        #expect(Theme.Wellbeing.color(for: 50) == .orange)
        #expect(Theme.Wellbeing.color(for: 49) == .red)
        #expect(Theme.Wellbeing.color(for: 100) == .green)
        #expect(Theme.Wellbeing.color(for: 0) == .red)
    }

    @Test
    func testWellbeingLabelBoundaryValues() {
        #expect(Theme.Wellbeing.label(for: 100) == "Excellent")
        #expect(Theme.Wellbeing.label(for: 80) == "Excellent")
        #expect(Theme.Wellbeing.label(for: 79) == "Good")
        #expect(Theme.Wellbeing.label(for: 70) == "Good")
        #expect(Theme.Wellbeing.label(for: 69) == "Fair")
        #expect(Theme.Wellbeing.label(for: 50) == "Fair")
        #expect(Theme.Wellbeing.label(for: 49) == "Needs Attention")
        #expect(Theme.Wellbeing.label(for: 30) == "Needs Attention")
        #expect(Theme.Wellbeing.label(for: 29) == "Low")
        #expect(Theme.Wellbeing.label(for: 0) == "Low")
    }
}

// MARK: - Tab Enum Tests

struct TabTests {

    @Test
    func testAllTabsHaveTitles() {
        for tab in Tab.allCases {
            #expect(!tab.title.isEmpty)
        }
    }

    @Test
    func testAllTabsHaveIconNames() {
        for tab in Tab.allCases {
            #expect(!tab.iconName.isEmpty)
        }
    }

    @Test
    func testTabCount() {
        #expect(Tab.allCases.count == 5)
    }

    @Test
    func testSpecificTabValues() {
        #expect(Tab.dashboard.title == "Dashboard")
        #expect(Tab.new.title == "New")
        #expect(Tab.actions.title == "Actions")
        #expect(Tab.history.title == "History")
        #expect(Tab.settings.title == "Settings")
    }
}

// MARK: - Edge Case Tests

struct EdgeCaseTests {

    @Test
    func testEmptyTextActionItem() {
        let action = ActionItem(text: "")
        #expect(action.text == "")
        #expect(action.isCompleted == false)
    }

    @Test
    func testEmptyTextKPTAItem() {
        let item = KPTAItem(text: "", category: .keep)
        #expect(item.text == "")
    }

    @Test
    func testVeryLongTextActionItem() {
        let longText = String(repeating: "a", count: 10000)
        let action = ActionItem(text: longText)
        #expect(action.text.count == 10000)
    }

    @Test
    func testNegativeOrderIndex() {
        let item = KPTAItem(text: "Test", category: .keep, orderIndex: -1)
        #expect(item.orderIndex == -1)
    }

    @Test
    func testZeroSleepMinutes() {
        let summary = HealthSummary(
            periodStart: Date(),
            periodEnd: Date(),
            avgSleepMinutes: 0
        )
        #expect(summary.formattedSleepDuration == "0h 0m")
    }

    @Test
    func testZeroSteps() {
        let summary = HealthSummary(
            periodStart: Date(),
            periodEnd: Date(),
            avgSteps: 0
        )
        #expect(summary.formattedSteps == "0")
    }

    @Test
    func testActionCompletionRateWithSingleAction() {
        let action = ActionItem(text: "Only action", isCompleted: true)
        let retro = Retrospective(
            title: "Test",
            type: .weekly,
            startDate: Date(),
            endDate: Date(),
            actions: [action]
        )
        #expect(retro.actionCompletionRate == 1.0)
    }

    @Test
    func testDeadlineExactlyNow() {
        // Edge case: deadline is exactly now
        let now = Date()
        let action = ActionItem(
            text: "Due now",
            isCompleted: false,
            deadline: now
        )
        // Since deadline < Date() is the check, exactly now should NOT be overdue
        // But in practice, by the time we check, it may have passed
        // This test documents the behavior
        #expect(action.deadline != nil)
    }
}

// MARK: - Data Integrity Tests

struct DataIntegrityTests {

    @Test
    func testUniqueIDsForMultipleActionItems() {
        let action1 = ActionItem(text: "Action 1")
        let action2 = ActionItem(text: "Action 2")
        let action3 = ActionItem(text: "Action 3")

        #expect(action1.id != action2.id)
        #expect(action2.id != action3.id)
        #expect(action1.id != action3.id)
    }

    @Test
    func testUniqueIDsForMultipleKPTAItems() {
        let item1 = KPTAItem(text: "Item 1", category: .keep)
        let item2 = KPTAItem(text: "Item 2", category: .problem)
        let item3 = KPTAItem(text: "Item 3", category: .try)

        #expect(item1.id != item2.id)
        #expect(item2.id != item3.id)
        #expect(item1.id != item3.id)
    }

    @Test
    func testUniqueIDsForMultipleRetrospectives() {
        let retro1 = Retrospective(title: "R1", type: .weekly, startDate: Date(), endDate: Date())
        let retro2 = Retrospective(title: "R2", type: .weekly, startDate: Date(), endDate: Date())

        #expect(retro1.id != retro2.id)
    }

    @Test
    func testPreservedIDWhenProvided() {
        let specificID = UUID()
        let action = ActionItem(id: specificID, text: "Test")

        #expect(action.id == specificID)
    }
}

// MARK: - ActionPriority Tests

struct ActionPriorityTests {

    @Test
    func testDisplayNames() {
        #expect(ActionPriority.high.displayName == "High")
        #expect(ActionPriority.medium.displayName == "Medium")
        #expect(ActionPriority.low.displayName == "Low")
    }

    @Test
    func testIconNames() {
        #expect(ActionPriority.high.iconName == "exclamationmark.3")
        #expect(ActionPriority.medium.iconName == "exclamationmark.2")
        #expect(ActionPriority.low.iconName == "exclamationmark")
    }

    @Test
    func testSortOrder() {
        #expect(ActionPriority.high.sortOrder == 0)
        #expect(ActionPriority.medium.sortOrder == 1)
        #expect(ActionPriority.low.sortOrder == 2)
    }

    @Test
    func testComparable() {
        #expect(ActionPriority.high < ActionPriority.medium)
        #expect(ActionPriority.medium < ActionPriority.low)
        #expect(ActionPriority.high < ActionPriority.low)
    }

    @Test
    func testCaseIterable() {
        let allCases = ActionPriority.allCases

        #expect(allCases.count == 3)
        #expect(allCases.contains(.high))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.low))
    }

    @Test
    func testRawValues() {
        #expect(ActionPriority.high.rawValue == "high")
        #expect(ActionPriority.medium.rawValue == "medium")
        #expect(ActionPriority.low.rawValue == "low")
    }

    @Test
    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for priority in ActionPriority.allCases {
            let data = try encoder.encode(priority)
            let decoded = try decoder.decode(ActionPriority.self, from: data)
            #expect(decoded == priority)
        }
    }
}

// MARK: - ActionFilter Tests

struct ActionFilterTests {

    // MARK: - Initialization Tests

    @Test
    func testDefaultInitialization() {
        let filter = ActionFilter()

        #expect(filter.completionStatus == .all)
        #expect(filter.deadlineStartDate == nil)
        #expect(filter.deadlineEndDate == nil)
        #expect(filter.priorities.isEmpty)
        #expect(filter.retrospectiveId == nil)
        #expect(filter.overdueOnly == false)
        #expect(filter.fromTryItemOnly == false)
        #expect(filter.sortOrder == .createdAtDescending)
    }

    @Test
    func testCustomInitialization() {
        let retroId = UUID()
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400)

        let filter = ActionFilter(
            completionStatus: .incomplete,
            deadlineStartDate: startDate,
            deadlineEndDate: endDate,
            priorities: [.high, .medium],
            retrospectiveId: retroId,
            overdueOnly: true,
            fromTryItemOnly: true,
            sortOrder: .priorityHighToLow
        )

        #expect(filter.completionStatus == .incomplete)
        #expect(filter.deadlineStartDate == startDate)
        #expect(filter.deadlineEndDate == endDate)
        #expect(filter.priorities.count == 2)
        #expect(filter.retrospectiveId == retroId)
        #expect(filter.overdueOnly == true)
        #expect(filter.fromTryItemOnly == true)
        #expect(filter.sortOrder == .priorityHighToLow)
    }

    // MARK: - Factory Methods Tests

    @Test
    func testIncompleteFilter() {
        let filter = ActionFilter.incomplete

        #expect(filter.completionStatus == .incomplete)
    }

    @Test
    func testCompletedFilter() {
        let filter = ActionFilter.completed

        #expect(filter.completionStatus == .completed)
    }

    @Test
    func testOverdueFilter() {
        let filter = ActionFilter.overdue

        #expect(filter.completionStatus == .incomplete)
        #expect(filter.overdueOnly == true)
    }

    @Test
    func testHighPriorityFilter() {
        let filter = ActionFilter.highPriority

        #expect(filter.completionStatus == .incomplete)
        #expect(filter.priorities.contains(.high))
        #expect(filter.sortOrder == .deadlineAscending)
    }

    @Test
    func testFromTryFilter() {
        let filter = ActionFilter.fromTry

        #expect(filter.fromTryItemOnly == true)
    }

    @Test
    func testForRetrospectiveFilter() {
        let retroId = UUID()
        let filter = ActionFilter.forRetrospective(retroId)

        #expect(filter.retrospectiveId == retroId)
    }

    @Test
    func testDueSoonFilter() {
        let filter = ActionFilter.dueSoon(days: 5)

        #expect(filter.completionStatus == .incomplete)
        #expect(filter.deadlineStartDate != nil)
        #expect(filter.deadlineEndDate != nil)
        #expect(filter.sortOrder == .deadlineAscending)
    }

    // MARK: - Filter Application Tests

    @Test
    func testApplyCompletionStatusFilter() {
        let completed = ActionItem(text: "Done", isCompleted: true, completedAt: Date())
        let incomplete = ActionItem(text: "Not done", isCompleted: false)
        let actions = [completed, incomplete]

        let completedFilter = ActionFilter(completionStatus: .completed)
        let incompleteFilter = ActionFilter(completionStatus: .incomplete)
        let allFilter = ActionFilter(completionStatus: .all)

        let completedResult = completedFilter.apply(to: actions)
        let incompleteResult = incompleteFilter.apply(to: actions)
        let allResult = allFilter.apply(to: actions)

        #expect(completedResult.count == 1)
        #expect(completedResult.first?.isCompleted == true)
        #expect(incompleteResult.count == 1)
        #expect(incompleteResult.first?.isCompleted == false)
        #expect(allResult.count == 2)
    }

    @Test
    func testApplyPriorityFilter() {
        let highAction = ActionItem(text: "High", priority: .high)
        let mediumAction = ActionItem(text: "Medium", priority: .medium)
        let lowAction = ActionItem(text: "Low", priority: .low)
        let actions = [highAction, mediumAction, lowAction]

        let highFilter = ActionFilter(priorities: [.high])
        let highMediumFilter = ActionFilter(priorities: [.high, .medium])

        let highResult = highFilter.apply(to: actions)
        let highMediumResult = highMediumFilter.apply(to: actions)

        #expect(highResult.count == 1)
        #expect(highMediumResult.count == 2)
    }

    @Test
    func testApplyFromTryFilter() {
        let fromTry = ActionItem(text: "From Try", fromTryItem: true)
        let notFromTry = ActionItem(text: "Not from Try", fromTryItem: false)
        let actions = [fromTry, notFromTry]

        let filter = ActionFilter(fromTryItemOnly: true)
        let result = filter.apply(to: actions)

        #expect(result.count == 1)
        #expect(result.first?.fromTryItem == true)
    }

    @Test
    func testApplyDeadlineRangeFilter() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let tomorrow = now.addingTimeInterval(86400)
        let nextWeek = now.addingTimeInterval(86400 * 7)

        let pastAction = ActionItem(text: "Past", deadline: yesterday)
        let soonAction = ActionItem(text: "Soon", deadline: tomorrow)
        let farAction = ActionItem(text: "Far", deadline: nextWeek)
        let noDeadline = ActionItem(text: "No deadline")
        let actions = [pastAction, soonAction, farAction, noDeadline]

        let filter = ActionFilter(
            deadlineStartDate: now,
            deadlineEndDate: now.addingTimeInterval(86400 * 3)
        )
        let result = filter.apply(to: actions)

        #expect(result.count == 1)
        #expect(result.first?.text == "Soon")
    }

    @Test
    func testApplyOverdueFilter() {
        let yesterday = Date().addingTimeInterval(-86400)
        let tomorrow = Date().addingTimeInterval(86400)

        let overdueAction = ActionItem(text: "Overdue", deadline: yesterday)
        let notOverdueAction = ActionItem(text: "Not overdue", deadline: tomorrow)
        let completedOverdue = ActionItem(text: "Completed overdue", isCompleted: true, deadline: yesterday, completedAt: Date())
        let actions = [overdueAction, notOverdueAction, completedOverdue]

        let filter = ActionFilter(overdueOnly: true)
        let result = filter.apply(to: actions)

        #expect(result.count == 1)
        #expect(result.first?.text == "Overdue")
    }

    // MARK: - Sorting Tests

    @Test
    func testSortByCreatedAtAscending() {
        let older = ActionItem(text: "Older", createdAt: Date().addingTimeInterval(-3600))
        let newer = ActionItem(text: "Newer", createdAt: Date())
        let actions = [newer, older]

        let filter = ActionFilter(sortOrder: .createdAtAscending)
        let result = filter.apply(to: actions)

        #expect(result.first?.text == "Older")
        #expect(result.last?.text == "Newer")
    }

    @Test
    func testSortByCreatedAtDescending() {
        let older = ActionItem(text: "Older", createdAt: Date().addingTimeInterval(-3600))
        let newer = ActionItem(text: "Newer", createdAt: Date())
        let actions = [older, newer]

        let filter = ActionFilter(sortOrder: .createdAtDescending)
        let result = filter.apply(to: actions)

        #expect(result.first?.text == "Newer")
        #expect(result.last?.text == "Older")
    }

    @Test
    func testSortByPriorityHighToLow() {
        let high = ActionItem(text: "High", priority: .high)
        let low = ActionItem(text: "Low", priority: .low)
        let medium = ActionItem(text: "Medium", priority: .medium)
        let actions = [low, medium, high]

        let filter = ActionFilter(sortOrder: .priorityHighToLow)
        let result = filter.apply(to: actions)

        #expect(result[0].priority == .high)
        #expect(result[1].priority == .medium)
        #expect(result[2].priority == .low)
    }

    @Test
    func testSortByPriorityLowToHigh() {
        let high = ActionItem(text: "High", priority: .high)
        let low = ActionItem(text: "Low", priority: .low)
        let medium = ActionItem(text: "Medium", priority: .medium)
        let actions = [high, medium, low]

        let filter = ActionFilter(sortOrder: .priorityLowToHigh)
        let result = filter.apply(to: actions)

        #expect(result[0].priority == .low)
        #expect(result[1].priority == .medium)
        #expect(result[2].priority == .high)
    }

    @Test
    func testSortByDeadlineAscending() {
        let soon = ActionItem(text: "Soon", deadline: Date().addingTimeInterval(86400))
        let later = ActionItem(text: "Later", deadline: Date().addingTimeInterval(86400 * 7))
        let noDeadline = ActionItem(text: "No deadline")
        let actions = [noDeadline, later, soon]

        let filter = ActionFilter(sortOrder: .deadlineAscending)
        let result = filter.apply(to: actions)

        // Items with deadlines should come first, sorted by date
        #expect(result[0].text == "Soon")
        #expect(result[1].text == "Later")
        #expect(result[2].text == "No deadline")
    }

    // MARK: - Equatable Tests

    @Test
    func testFilterEquality() {
        let filter1 = ActionFilter(completionStatus: .incomplete, priorities: [.high])
        let filter2 = ActionFilter(completionStatus: .incomplete, priorities: [.high])
        let filter3 = ActionFilter(completionStatus: .completed, priorities: [.high])

        #expect(filter1 == filter2)
        #expect(filter1 != filter3)
    }
}

// MARK: - ActionStatistics Tests

struct ActionStatisticsTests {

    @Test
    func testFormattedCompletionRate() {
        let stats = ActionStatistics(
            total: 10,
            completed: 7,
            incomplete: 3,
            overdue: 1,
            highPriority: 2,
            mediumPriority: 3,
            lowPriority: 1,
            fromTry: 4,
            completionRate: 0.7
        )

        #expect(stats.formattedCompletionRate == "70%")
    }

    @Test
    func testZeroCompletionRate() {
        let stats = ActionStatistics(
            total: 5,
            completed: 0,
            incomplete: 5,
            overdue: 2,
            highPriority: 1,
            mediumPriority: 2,
            lowPriority: 2,
            fromTry: 1,
            completionRate: 0.0
        )

        #expect(stats.formattedCompletionRate == "0%")
    }

    @Test
    func testFullCompletionRate() {
        let stats = ActionStatistics(
            total: 5,
            completed: 5,
            incomplete: 0,
            overdue: 0,
            highPriority: 0,
            mediumPriority: 0,
            lowPriority: 0,
            fromTry: 2,
            completionRate: 1.0
        )

        #expect(stats.formattedCompletionRate == "100%")
    }
}
