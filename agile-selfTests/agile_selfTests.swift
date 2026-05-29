//
//  agile_selfTests.swift
//  agile-selfTests
//
//  Created by Tetsuya Maeda on 2025/11/30.
//

import Testing
import Foundation
@testable import agile_self

// MARK: - DailyCheckIn Tests

struct DailyCheckInTests {

    // MARK: - Initialization Tests

    @Test
    func initializationWithDefaults() {
        let checkIn = DailyCheckIn()

        // Neutral default is 3 on the 1–5 scale.
        #expect(checkIn.energyScore == 3)
        #expect(checkIn.focusScore == 3)
        #expect(checkIn.stressScore == 3)
        #expect(checkIn.growthScore == 3)
        #expect(checkIn.note == nil)
        #expect(checkIn.sentimentScore == nil)
        #expect(checkIn.dailyInsight == nil)
    }

    @Test
    func initializationWithCustomValues() {
        let id = UUID()
        let date = Date()
        let createdAt = Date()

        let checkIn = DailyCheckIn(
            id: id,
            date: date,
            energyScore: 4,
            focusScore: 5,
            stressScore: 2,
            growthScore: 4,
            note: "Great day",
            sentimentScore: 0.85,
            dailyInsight: "You had a productive day",
            createdAt: createdAt
        )

        #expect(checkIn.id == id)
        #expect(checkIn.date == date)
        #expect(checkIn.energyScore == 4)
        #expect(checkIn.focusScore == 5)
        #expect(checkIn.stressScore == 2)
        #expect(checkIn.growthScore == 4)
        #expect(checkIn.note == "Great day")
        #expect(checkIn.sentimentScore == 0.85)
        #expect(checkIn.dailyInsight == "You had a productive day")
        #expect(checkIn.createdAt == createdAt)
    }

    @Test
    func defaultDateIsStartOfToday() {
        let checkIn = DailyCheckIn()
        let expectedDate = Calendar.current.startOfDay(for: Date())

        #expect(checkIn.date == expectedDate)
    }

    // MARK: - Composite Score Tests

    @Test
    func compositeScoreWithDefaultValues() {
        let checkIn = DailyCheckIn()
        // Plain mean of all four 3s: (3 + 3 + 3 + 3) / 4.0 = 3.0
        #expect(checkIn.compositeScore == 3.0)
    }

    @Test
    func defaultCheckInCompositeIsExactlyThree() {
        // A neutral default check-in must score exactly 3.0 on the 1–5 scale.
        #expect(DailyCheckIn().compositeScore == 3.0)
    }

    @Test
    func compositeScoreWithMaxValues() {
        let checkIn = DailyCheckIn(
            energyScore: 5,
            focusScore: 5,
            stressScore: 5,  // High calm is good
            growthScore: 5
        )
        // (5 + 5 + 5 + 5) / 4.0 = 5.0
        #expect(checkIn.compositeScore == 5.0)
    }

    @Test
    func compositeScoreWithMinValues() {
        let checkIn = DailyCheckIn(
            energyScore: 1,
            focusScore: 1,
            stressScore: 1,  // Low calm is bad
            growthScore: 1
        )
        // (1 + 1 + 1 + 1) / 4.0 = 1.0
        #expect(checkIn.compositeScore == 1.0)
    }

    @Test
    func compositeScoreRisesWithCalm() {
        // Two check-ins identical except for the calm axis (stored as stressScore).
        let lowCalm = DailyCheckIn(energyScore: 3, focusScore: 3, stressScore: 1, growthScore: 3)
        let highCalm = DailyCheckIn(energyScore: 3, focusScore: 3, stressScore: 5, growthScore: 3)

        // Higher calm should yield a higher composite score (up = better for all axes).
        #expect(highCalm.compositeScore > lowCalm.compositeScore)
    }

    @Test
    func compositeScoreWithMixedValues() {
        let checkIn = DailyCheckIn(
            energyScore: 4,
            focusScore: 3,
            stressScore: 2,
            growthScore: 3
        )
        // (4 + 3 + 2 + 3) / 4.0 = 12 / 4.0 = 3.0
        #expect(checkIn.compositeScore == 3.0)
    }

    // MARK: - score(for:) Tests

    @Test
    func scoreForEnergy() {
        let checkIn = DailyCheckIn(energyScore: 4)
        #expect(checkIn.score(for: .energy) == 4)
    }

    @Test
    func scoreForFocus() {
        let checkIn = DailyCheckIn(focusScore: 3)
        #expect(checkIn.score(for: .focus) == 3)
    }

    @Test
    func scoreForStress() {
        let checkIn = DailyCheckIn(stressScore: 4)
        #expect(checkIn.score(for: .stress) == 4)
    }

    @Test
    func scoreForGrowth() {
        let checkIn = DailyCheckIn(growthScore: 5)
        #expect(checkIn.score(for: .growth) == 5)
    }

    @Test
    func scoreForAllDimensions() {
        let checkIn = DailyCheckIn(
            energyScore: 1,
            focusScore: 2,
            stressScore: 3,
            growthScore: 4
        )
        for dimension in DimensionType.allCases {
            let score = checkIn.score(for: dimension)
            switch dimension {
            case .energy: #expect(score == 1)
            case .focus: #expect(score == 2)
            case .stress: #expect(score == 3)
            case .growth: #expect(score == 4)
            }
        }
    }

    // MARK: - setScore(_:for:) Tests

    @Test
    func setScoreForEnergy() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(5, for: .energy)
        #expect(checkIn.energyScore == 5)
    }

    @Test
    func setScoreForFocus() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(2, for: .focus)
        #expect(checkIn.focusScore == 2)
    }

    @Test
    func setScoreForStress() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(4, for: .stress)
        #expect(checkIn.stressScore == 4)
    }

    @Test
    func setScoreForGrowth() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(1, for: .growth)
        #expect(checkIn.growthScore == 1)
    }

    @Test
    func setScoreClampsAboveMaximum() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(15, for: .energy)
        #expect(checkIn.energyScore == 5)
    }

    @Test
    func setScoreClampsBelowMinimum() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(0, for: .focus)
        #expect(checkIn.focusScore == 1)
    }

    @Test
    func setScoreClampsNegativeValue() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(-5, for: .stress)
        #expect(checkIn.stressScore == 1)
    }

    @Test
    func setScoreClampsLargeValue() {
        let checkIn = DailyCheckIn()
        checkIn.setScore(1000, for: .growth)
        #expect(checkIn.growthScore == 5)
    }

    @Test
    func setScoreBoundaryValues() {
        let checkIn = DailyCheckIn()

        checkIn.setScore(1, for: .energy)
        #expect(checkIn.energyScore == 1)

        checkIn.setScore(5, for: .energy)
        #expect(checkIn.energyScore == 5)
    }

    // MARK: - Unique ID Tests

    @Test
    func uniqueIDsGenerated() {
        let checkIn1 = DailyCheckIn()
        let checkIn2 = DailyCheckIn()
        #expect(checkIn1.id != checkIn2.id)
    }

    @Test
    func preservedIDWhenProvided() {
        let specificID = UUID()
        let checkIn = DailyCheckIn(id: specificID)
        #expect(checkIn.id == specificID)
    }
}

// MARK: - HealthSnapshot Tests

struct HealthSnapshotTests {

    // MARK: - Initialization Tests

    @Test
    func initializationWithDefaults() {
        let snapshot = HealthSnapshot()

        #expect(snapshot.sleepMinutes == nil)
        #expect(snapshot.steps == nil)
        #expect(snapshot.activeCalories == nil)
        #expect(snapshot.exerciseMinutes == nil)
        #expect(snapshot.restingHeartRate == nil)
        #expect(snapshot.runningDistanceMeters == nil)
        #expect(snapshot.screenTimeMinutes == nil)
    }

    @Test
    func initializationWithAllValues() {
        let id = UUID()
        let date = Date()
        let createdAt = Date()

        let snapshot = HealthSnapshot(
            id: id,
            date: date,
            sleepMinutes: 450,
            steps: 8500,
            activeCalories: 320,
            exerciseMinutes: 45,
            restingHeartRate: 62,
            runningDistanceMeters: 5200.0,
            screenTimeMinutes: 195,
            createdAt: createdAt
        )

        #expect(snapshot.id == id)
        #expect(snapshot.date == date)
        #expect(snapshot.sleepMinutes == 450)
        #expect(snapshot.steps == 8500)
        #expect(snapshot.activeCalories == 320)
        #expect(snapshot.exerciseMinutes == 45)
        #expect(snapshot.restingHeartRate == 62)
        #expect(snapshot.runningDistanceMeters == 5200.0)
        #expect(snapshot.screenTimeMinutes == 195)
        #expect(snapshot.createdAt == createdAt)
    }

    // MARK: - formattedSleep Tests

    @Test
    func formattedSleepWithNilValue() {
        let snapshot = HealthSnapshot()
        #expect(snapshot.formattedSleep == nil)
    }

    @Test
    func formattedSleepWithHoursAndMinutes() {
        let snapshot = HealthSnapshot(sleepMinutes: 450)
        // 450 min = 7h 30m
        #expect(snapshot.formattedSleep == "7h 30m")
    }

    @Test
    func formattedSleepWithExactHours() {
        let snapshot = HealthSnapshot(sleepMinutes: 480)
        // 480 min = 8h, 0 remaining -> "8h" (no remaining to show)
        #expect(snapshot.formattedSleep == "8h")
    }

    @Test
    func formattedSleepWithOnlyMinutes() {
        let snapshot = HealthSnapshot(sleepMinutes: 45)
        // 45 min = 0h 45m -> "45m"
        #expect(snapshot.formattedSleep == "45m")
    }

    @Test
    func formattedSleepWithZeroMinutes() {
        let snapshot = HealthSnapshot(sleepMinutes: 0)
        // 0 min = 0h 0m -> "0m" (hours = 0, remaining = 0, falls to else)
        #expect(snapshot.formattedSleep == "0m")
    }

    @Test
    func formattedSleepWithOneMinute() {
        let snapshot = HealthSnapshot(sleepMinutes: 1)
        #expect(snapshot.formattedSleep == "1m")
    }

    @Test
    func formattedSleepWithOneHour() {
        let snapshot = HealthSnapshot(sleepMinutes: 60)
        #expect(snapshot.formattedSleep == "1h")
    }

    @Test
    func formattedSleepWithOneHourOneMinute() {
        let snapshot = HealthSnapshot(sleepMinutes: 61)
        #expect(snapshot.formattedSleep == "1h 1m")
    }

    // MARK: - formattedSteps Tests

    @Test
    func formattedStepsWithNilValue() {
        let snapshot = HealthSnapshot()
        #expect(snapshot.formattedSteps == nil)
    }

    @Test
    func formattedStepsWithSmallValue() {
        let snapshot = HealthSnapshot(steps: 500)
        #expect(snapshot.formattedSteps == "500")
    }

    @Test
    func formattedStepsWithZero() {
        let snapshot = HealthSnapshot(steps: 0)
        #expect(snapshot.formattedSteps == "0")
    }

    @Test
    func formattedStepsWithThousandsSeparator() {
        let snapshot = HealthSnapshot(steps: 10000)
        let formatted = snapshot.formattedSteps
        #expect(formatted != nil)
        // NumberFormatter with .decimal style uses locale-specific separator.
        // For most locales this will be "10,000" or "10.000".
        #expect(formatted!.contains("10"))
    }

    @Test
    func formattedStepsWithLargeValue() {
        let snapshot = HealthSnapshot(steps: 25432)
        let formatted = snapshot.formattedSteps
        #expect(formatted != nil)
        #expect(formatted!.contains("25"))
    }

    // MARK: - formattedScreenTime Tests

    @Test
    func formattedScreenTimeWithNilValue() {
        let snapshot = HealthSnapshot()
        #expect(snapshot.formattedScreenTime == nil)
    }

    @Test
    func formattedScreenTimeWithHoursAndMinutes() {
        let snapshot = HealthSnapshot(screenTimeMinutes: 195)
        // 195 min = 3h 15m
        #expect(snapshot.formattedScreenTime == "3h 15m")
    }

    @Test
    func formattedScreenTimeWithExactHours() {
        let snapshot = HealthSnapshot(screenTimeMinutes: 120)
        #expect(snapshot.formattedScreenTime == "2h")
    }

    @Test
    func formattedScreenTimeWithOnlyMinutes() {
        let snapshot = HealthSnapshot(screenTimeMinutes: 30)
        #expect(snapshot.formattedScreenTime == "30m")
    }

    @Test
    func formattedScreenTimeWithZero() {
        let snapshot = HealthSnapshot(screenTimeMinutes: 0)
        #expect(snapshot.formattedScreenTime == "0m")
    }

    // MARK: - formattedRunDistance Tests

    @Test
    func formattedRunDistanceWithNilValue() {
        let snapshot = HealthSnapshot()
        #expect(snapshot.formattedRunDistance == nil)
    }

    @Test
    func formattedRunDistanceWithKilometers() {
        let snapshot = HealthSnapshot(runningDistanceMeters: 5200.0)
        #expect(snapshot.formattedRunDistance == "5.2km")
    }

    @Test
    func formattedRunDistanceWithExactKilometers() {
        let snapshot = HealthSnapshot(runningDistanceMeters: 3000.0)
        #expect(snapshot.formattedRunDistance == "3.0km")
    }

    @Test
    func formattedRunDistanceWithSmallDistance() {
        let snapshot = HealthSnapshot(runningDistanceMeters: 500.0)
        #expect(snapshot.formattedRunDistance == "0.5km")
    }

    @Test
    func formattedRunDistanceWithZero() {
        let snapshot = HealthSnapshot(runningDistanceMeters: 0.0)
        #expect(snapshot.formattedRunDistance == "0.0km")
    }

    @Test
    func formattedRunDistanceWithLargeValue() {
        let snapshot = HealthSnapshot(runningDistanceMeters: 42195.0)
        #expect(snapshot.formattedRunDistance == "42.2km")
    }

    // MARK: - formattedHeartRate Tests

    @Test
    func formattedHeartRateWithNilValue() {
        let snapshot = HealthSnapshot()
        #expect(snapshot.formattedHeartRate == nil)
    }

    @Test
    func formattedHeartRateWithValue() {
        let snapshot = HealthSnapshot(restingHeartRate: 62)
        #expect(snapshot.formattedHeartRate == "62 bpm")
    }

    @Test
    func formattedHeartRateWithHighValue() {
        let snapshot = HealthSnapshot(restingHeartRate: 95)
        #expect(snapshot.formattedHeartRate == "95 bpm")
    }

    @Test
    func formattedHeartRateWithLowValue() {
        let snapshot = HealthSnapshot(restingHeartRate: 45)
        #expect(snapshot.formattedHeartRate == "45 bpm")
    }

    // MARK: - Unique ID Tests

    @Test
    func uniqueIDsGenerated() {
        let snapshot1 = HealthSnapshot()
        let snapshot2 = HealthSnapshot()
        #expect(snapshot1.id != snapshot2.id)
    }
}

// MARK: - ActionItemV2 Tests

struct ActionItemV2Tests {

    // MARK: - Initialization Tests

    @Test
    func initializationWithDefaults() {
        let action = ActionItemV2(text: "Complete weekly report")

        #expect(action.text == "Complete weekly report")
        #expect(action.isCompleted == false)
        #expect(action.deadline == nil)
        #expect(action.completedAt == nil)
        #expect(action.priority == .medium)
        #expect(action.source == .manual)
        #expect(action.notes == nil)
    }

    @Test
    func initializationWithAllParameters() {
        let id = UUID()
        let deadline = Date().addingTimeInterval(86400)
        let createdAt = Date()
        let updatedAt = Date()

        let action = ActionItemV2(
            id: id,
            text: "Test action",
            isCompleted: true,
            deadline: deadline,
            completedAt: createdAt,
            priority: .high,
            source: .weeklyReview,
            notes: "Test notes",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        #expect(action.id == id)
        #expect(action.text == "Test action")
        #expect(action.isCompleted == true)
        #expect(action.deadline == deadline)
        #expect(action.completedAt == createdAt)
        #expect(action.priority == .high)
        #expect(action.source == .weeklyReview)
        #expect(action.notes == "Test notes")
        #expect(action.createdAt == createdAt)
        #expect(action.updatedAt == updatedAt)
    }

    @Test
    func initializationWithAISuggestedSource() {
        let action = ActionItemV2(text: "AI suggestion", source: .aiSuggested)
        #expect(action.source == .aiSuggested)
    }

    @Test
    func initializationWithWeeklyReviewSource() {
        let action = ActionItemV2(text: "Review action", source: .weeklyReview)
        #expect(action.source == .weeklyReview)
    }

    // MARK: - isOverdue Tests

    @Test
    func isOverdueWhenNoDeadline() {
        let action = ActionItemV2(text: "No deadline action")
        #expect(action.isOverdue == false)
    }

    @Test
    func isOverdueWhenCompletedPastDeadline() {
        let pastDeadline = Date().addingTimeInterval(-86400)
        let action = ActionItemV2(
            text: "Completed action",
            isCompleted: true,
            deadline: pastDeadline,
            completedAt: Date()
        )
        #expect(action.isOverdue == false, "Completed items should never be overdue")
    }

    @Test
    func isOverdueWhenDeadlinePassed() {
        let pastDeadline = Date().addingTimeInterval(-86400)
        let action = ActionItemV2(
            text: "Late action",
            isCompleted: false,
            deadline: pastDeadline
        )
        #expect(action.isOverdue == true)
    }

    @Test
    func isOverdueWhenDeadlineInFuture() {
        let futureDeadline = Date().addingTimeInterval(86400)
        let action = ActionItemV2(
            text: "Future action",
            isCompleted: false,
            deadline: futureDeadline
        )
        #expect(action.isOverdue == false)
    }

    @Test
    func isOverdueWhenDeadlineJustPassed() {
        // 1 second ago
        let justPast = Date().addingTimeInterval(-1)
        let action = ActionItemV2(text: "Just late", deadline: justPast)
        #expect(action.isOverdue == true)
    }

    // MARK: - daysUntilDeadline Tests

    @Test
    func daysUntilDeadlineWithNoDeadline() {
        let action = ActionItemV2(text: "No deadline")
        #expect(action.daysUntilDeadline == nil)
    }

    @Test
    func daysUntilDeadlineWithFutureDeadline() {
        // 3 days from now
        let futureDeadline = Date().addingTimeInterval(86400 * 3)
        let action = ActionItemV2(text: "Future", deadline: futureDeadline)
        let days = action.daysUntilDeadline
        #expect(days != nil)
        // Allow small variance due to time-of-day
        #expect(days! >= 2 && days! <= 3)
    }

    @Test
    func daysUntilDeadlineWithPastDeadline() {
        // 2 days ago
        let pastDeadline = Date().addingTimeInterval(-86400 * 2)
        let action = ActionItemV2(text: "Past", deadline: pastDeadline)
        let days = action.daysUntilDeadline
        #expect(days != nil)
        #expect(days! < 0)
    }

    // MARK: - toggleCompletion() Tests

    @Test
    func toggleCompletionFromIncomplete() {
        let action = ActionItemV2(text: "Test action")
        #expect(action.isCompleted == false)
        #expect(action.completedAt == nil)

        action.toggleCompletion()

        #expect(action.isCompleted == true)
        #expect(action.completedAt != nil)
    }

    @Test
    func toggleCompletionFromComplete() {
        let action = ActionItemV2(
            text: "Test action",
            isCompleted: true,
            completedAt: Date()
        )

        action.toggleCompletion()

        #expect(action.isCompleted == false)
        #expect(action.completedAt == nil)
    }

    @Test
    func toggleCompletionUpdatesTimestamp() {
        let originalUpdatedAt = Date().addingTimeInterval(-3600)
        let action = ActionItemV2(text: "Test", updatedAt: originalUpdatedAt)

        action.toggleCompletion()

        #expect(action.updatedAt > originalUpdatedAt)
    }

    @Test
    func toggleCompletionTwiceRestoresState() {
        let action = ActionItemV2(text: "Test action")

        action.toggleCompletion()
        #expect(action.isCompleted == true)

        action.toggleCompletion()
        #expect(action.isCompleted == false)
        #expect(action.completedAt == nil)
    }

    @Test
    func toggleCompletionSetsCompletedAtToCurrentTime() {
        let action = ActionItemV2(text: "Test")
        let beforeToggle = Date()

        action.toggleCompletion()

        let afterToggle = Date()
        guard let completedAt = action.completedAt else {
            Issue.record("completedAt should not be nil after toggling to completed")
            return
        }
        #expect(completedAt >= beforeToggle)
        #expect(completedAt <= afterToggle)
    }

    // MARK: - Empty / Edge Cases

    @Test
    func emptyText() {
        let action = ActionItemV2(text: "")
        #expect(action.text == "")
    }

    @Test
    func veryLongText() {
        let longText = String(repeating: "a", count: 10000)
        let action = ActionItemV2(text: longText)
        #expect(action.text.count == 10000)
    }

    // MARK: - Unique ID Tests

    @Test
    func uniqueIDsGenerated() {
        let action1 = ActionItemV2(text: "Action 1")
        let action2 = ActionItemV2(text: "Action 2")
        let action3 = ActionItemV2(text: "Action 3")

        #expect(action1.id != action2.id)
        #expect(action2.id != action3.id)
        #expect(action1.id != action3.id)
    }

    @Test
    func preservedIDWhenProvided() {
        let specificID = UUID()
        let action = ActionItemV2(id: specificID, text: "Test")
        #expect(action.id == specificID)
    }
}

// MARK: - ActionPriority Tests

struct ActionPriorityTests {

    @Test
    func displayNames() {
        #expect(ActionPriority.high.displayName == "High")
        #expect(ActionPriority.medium.displayName == "Medium")
        #expect(ActionPriority.low.displayName == "Low")
    }

    @Test
    func iconNames() {
        #expect(ActionPriority.high.iconName == "exclamationmark.3")
        #expect(ActionPriority.medium.iconName == "exclamationmark.2")
        #expect(ActionPriority.low.iconName == "exclamationmark")
    }

    @Test
    func sortOrder() {
        #expect(ActionPriority.high.sortOrder == 0)
        #expect(ActionPriority.medium.sortOrder == 1)
        #expect(ActionPriority.low.sortOrder == 2)
    }

    @Test
    func comparable() {
        #expect(ActionPriority.high < ActionPriority.medium)
        #expect(ActionPriority.medium < ActionPriority.low)
        #expect(ActionPriority.high < ActionPriority.low)
    }

    @Test
    func comparableNotEqualValues() {
        #expect(!(ActionPriority.high < ActionPriority.high))
        #expect(!(ActionPriority.medium > ActionPriority.low))
    }

    @Test
    func caseIterable() {
        let allCases = ActionPriority.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.high))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.low))
    }

    @Test
    func rawValues() {
        #expect(ActionPriority.high.rawValue == "high")
        #expect(ActionPriority.medium.rawValue == "medium")
        #expect(ActionPriority.low.rawValue == "low")
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for priority in ActionPriority.allCases {
            let data = try encoder.encode(priority)
            let decoded = try decoder.decode(ActionPriority.self, from: data)
            #expect(decoded == priority)
        }
    }

    @Test
    func decodableFromString() throws {
        let decoder = JSONDecoder()

        let highData = Data("\"high\"".utf8)
        let decoded = try decoder.decode(ActionPriority.self, from: highData)
        #expect(decoded == .high)
    }

    @Test
    func decodableFailsForInvalidString() {
        let decoder = JSONDecoder()
        let invalidData = Data("\"critical\"".utf8)

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(ActionPriority.self, from: invalidData)
        }
    }

    @Test
    func sortingByPriority() {
        var priorities: [ActionPriority] = [.low, .high, .medium, .low, .high]
        priorities.sort()
        #expect(priorities == [.high, .high, .medium, .low, .low])
    }
}

// MARK: - ActionSource Tests

struct ActionSourceTests {

    @Test
    func rawValues() {
        #expect(ActionSource.weeklyReview.rawValue == "weeklyReview")
        #expect(ActionSource.manual.rawValue == "manual")
        #expect(ActionSource.aiSuggested.rawValue == "aiSuggested")
    }

    @Test
    func caseIterable() {
        let allCases = ActionSource.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.weeklyReview))
        #expect(allCases.contains(.manual))
        #expect(allCases.contains(.aiSuggested))
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for source in ActionSource.allCases {
            let data = try encoder.encode(source)
            let decoded = try decoder.decode(ActionSource.self, from: data)
            #expect(decoded == source)
        }
    }

    @Test
    func decodableFromString() throws {
        let decoder = JSONDecoder()

        let data = Data("\"aiSuggested\"".utf8)
        let decoded = try decoder.decode(ActionSource.self, from: data)
        #expect(decoded == .aiSuggested)
    }

    @Test
    func decodableFailsForInvalidString() {
        let decoder = JSONDecoder()
        let invalidData = Data("\"unknown\"".utf8)

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(ActionSource.self, from: invalidData)
        }
    }
}

// MARK: - Streak Tests

struct StreakTests {

    // MARK: - Initialization Tests

    @Test
    func initializationWithDefaults() {
        let streak = Streak()

        #expect(streak.currentStreak == 0)
        #expect(streak.longestStreak == 0)
        #expect(streak.lastCheckInDate == nil)
        #expect(streak.totalCheckIns == 0)
    }

    @Test
    func initializationWithCustomValues() {
        let id = UUID()
        let lastDate = Date()
        let createdAt = Date()

        let streak = Streak(
            id: id,
            currentStreak: 7,
            longestStreak: 14,
            lastCheckInDate: lastDate,
            totalCheckIns: 50,
            createdAt: createdAt
        )

        #expect(streak.id == id)
        #expect(streak.currentStreak == 7)
        #expect(streak.longestStreak == 14)
        #expect(streak.lastCheckInDate == lastDate)
        #expect(streak.totalCheckIns == 50)
        #expect(streak.createdAt == createdAt)
    }

    // MARK: - isActiveToday Tests

    @Test
    func isActiveTodayWhenNoCheckIn() {
        let streak = Streak()
        #expect(streak.isActiveToday == false)
    }

    @Test
    func isActiveTodayWhenCheckedInToday() {
        let streak = Streak(lastCheckInDate: Date())
        #expect(streak.isActiveToday == true)
    }

    @Test
    func isActiveTodayWhenCheckedInYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let streak = Streak(lastCheckInDate: yesterday)
        #expect(streak.isActiveToday == false)
    }

    // MARK: - recordCheckIn(on:) Tests

    @Test
    func firstCheckIn() {
        let streak = Streak()
        let today = Date()

        streak.recordCheckIn(on: today)

        #expect(streak.currentStreak == 1)
        #expect(streak.longestStreak == 1)
        #expect(streak.totalCheckIns == 1)
        #expect(streak.lastCheckInDate != nil)
    }

    @Test
    func sameDayCheckInIsNoOp() {
        let streak = Streak()
        let today = Date()

        streak.recordCheckIn(on: today)
        streak.recordCheckIn(on: today)

        #expect(streak.currentStreak == 1)
        #expect(streak.totalCheckIns == 1, "Same-day check-in should not increment total")
    }

    @Test
    func consecutiveDayExtendsStreak() {
        let streak = Streak()
        let calendar = Calendar.current

        let day1 = calendar.startOfDay(for: Date())
        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!

        streak.recordCheckIn(on: day1)
        #expect(streak.currentStreak == 1)

        streak.recordCheckIn(on: day2)
        #expect(streak.currentStreak == 2)
        #expect(streak.longestStreak == 2)
        #expect(streak.totalCheckIns == 2)
    }

    @Test
    func gapResetsStreak() {
        let streak = Streak()
        let calendar = Calendar.current

        let day1 = calendar.startOfDay(for: Date())
        let day3 = calendar.date(byAdding: .day, value: 2, to: day1)!  // Skip a day

        streak.recordCheckIn(on: day1)
        #expect(streak.currentStreak == 1)

        streak.recordCheckIn(on: day3)
        #expect(streak.currentStreak == 1, "Gap should reset streak to 1")
        #expect(streak.totalCheckIns == 2)
    }

    @Test
    func longestStreakPreservedAfterReset() {
        let streak = Streak()
        let calendar = Calendar.current

        let day1 = calendar.startOfDay(for: Date())
        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!
        let day3 = calendar.date(byAdding: .day, value: 2, to: day1)!
        // Gap: skip day 4
        let day5 = calendar.date(byAdding: .day, value: 4, to: day1)!

        streak.recordCheckIn(on: day1)
        streak.recordCheckIn(on: day2)
        streak.recordCheckIn(on: day3)
        #expect(streak.currentStreak == 3)
        #expect(streak.longestStreak == 3)

        streak.recordCheckIn(on: day5)
        #expect(streak.currentStreak == 1, "Gap should reset current streak")
        #expect(streak.longestStreak == 3, "Longest streak should be preserved")
        #expect(streak.totalCheckIns == 4)
    }

    @Test
    func longestStreakUpdatesWhenSurpassed() {
        let streak = Streak()
        let calendar = Calendar.current

        let day1 = calendar.startOfDay(for: Date())

        // Build a streak of 5 consecutive days
        for i in 0..<5 {
            let day = calendar.date(byAdding: .day, value: i, to: day1)!
            streak.recordCheckIn(on: day)
        }

        #expect(streak.currentStreak == 5)
        #expect(streak.longestStreak == 5)
    }

    @Test
    func multipleGapsAndStreaks() {
        let streak = Streak()
        let calendar = Calendar.current

        let base = calendar.startOfDay(for: Date())

        // Streak 1: days 0, 1, 2 (streak = 3)
        for i in 0..<3 {
            streak.recordCheckIn(on: calendar.date(byAdding: .day, value: i, to: base)!)
        }
        #expect(streak.currentStreak == 3)

        // Gap: skip day 3
        // Streak 2: days 4, 5 (streak = 2)
        streak.recordCheckIn(on: calendar.date(byAdding: .day, value: 4, to: base)!)
        #expect(streak.currentStreak == 1)
        streak.recordCheckIn(on: calendar.date(byAdding: .day, value: 5, to: base)!)
        #expect(streak.currentStreak == 2)

        #expect(streak.longestStreak == 3)
        #expect(streak.totalCheckIns == 5)
    }

    // MARK: - Unique ID Tests

    @Test
    func uniqueIDsGenerated() {
        let streak1 = Streak()
        let streak2 = Streak()
        #expect(streak1.id != streak2.id)
    }
}

// MARK: - UserProfile Tests

struct UserProfileTests {

    // MARK: - Initialization Tests

    @Test
    func initializationWithDefaults() {
        let profile = UserProfile()

        #expect(profile.displayName == nil)
        #expect(profile.checkInReminderHour == 21)
        #expect(profile.checkInReminderMinute == 0)
        #expect(profile.weeklyReviewDay == 6)
        #expect(profile.subscriptionTier == .free)
        #expect(profile.allowCloudAI == false)
        #expect(profile.hasCompletedOnboarding == false)
    }

    @Test
    func initializationWithAllParameters() {
        let id = UUID()
        let createdAt = Date()

        let profile = UserProfile(
            id: id,
            displayName: "Tetsuya",
            checkInReminderHour: 22,
            checkInReminderMinute: 30,
            weeklyReviewDay: 1,
            subscriptionTier: .premium,
            allowCloudAI: true,
            hasCompletedOnboarding: true,
            createdAt: createdAt
        )

        #expect(profile.id == id)
        #expect(profile.displayName == "Tetsuya")
        #expect(profile.checkInReminderHour == 22)
        #expect(profile.checkInReminderMinute == 30)
        #expect(profile.weeklyReviewDay == 1)
        #expect(profile.subscriptionTier == .premium)
        #expect(profile.allowCloudAI == true)
        #expect(profile.hasCompletedOnboarding == true)
        #expect(profile.createdAt == createdAt)
    }

    // MARK: - Property Mutation Tests

    @Test
    func updateDisplayName() {
        let profile = UserProfile()
        profile.displayName = "New Name"
        #expect(profile.displayName == "New Name")
    }

    @Test
    func updateReminderTime() {
        let profile = UserProfile()
        profile.checkInReminderHour = 8
        profile.checkInReminderMinute = 45
        #expect(profile.checkInReminderHour == 8)
        #expect(profile.checkInReminderMinute == 45)
    }

    @Test
    func updateSubscriptionTier() {
        let profile = UserProfile()
        #expect(profile.subscriptionTier == .free)

        profile.subscriptionTier = .premium
        #expect(profile.subscriptionTier == .premium)
    }

    @Test
    func updateCloudAIFlag() {
        let profile = UserProfile()
        #expect(profile.allowCloudAI == false)

        profile.allowCloudAI = true
        #expect(profile.allowCloudAI == true)
    }

    @Test
    func updateOnboardingFlag() {
        let profile = UserProfile()
        #expect(profile.hasCompletedOnboarding == false)

        profile.hasCompletedOnboarding = true
        #expect(profile.hasCompletedOnboarding == true)
    }

    // MARK: - Unique ID Tests

    @Test
    func uniqueIDsGenerated() {
        let profile1 = UserProfile()
        let profile2 = UserProfile()
        #expect(profile1.id != profile2.id)
    }

    @Test
    func preservedIDWhenProvided() {
        let specificID = UUID()
        let profile = UserProfile(id: specificID)
        #expect(profile.id == specificID)
    }
}

// MARK: - SubscriptionTier Tests

struct SubscriptionTierTests {

    @Test
    func rawValues() {
        #expect(SubscriptionTier.free.rawValue == "free")
        #expect(SubscriptionTier.premium.rawValue == "premium")
    }

    @Test
    func caseIterable() {
        let allCases = SubscriptionTier.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.free))
        #expect(allCases.contains(.premium))
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for tier in SubscriptionTier.allCases {
            let data = try encoder.encode(tier)
            let decoded = try decoder.decode(SubscriptionTier.self, from: data)
            #expect(decoded == tier)
        }
    }

    @Test
    func decodableFromString() throws {
        let decoder = JSONDecoder()

        let data = Data("\"premium\"".utf8)
        let decoded = try decoder.decode(SubscriptionTier.self, from: data)
        #expect(decoded == .premium)
    }

    @Test
    func decodableFailsForInvalidString() {
        let decoder = JSONDecoder()
        let invalidData = Data("\"enterprise\"".utf8)

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(SubscriptionTier.self, from: invalidData)
        }
    }
}

// MARK: - WeeklyReview Tests

struct WeeklyReviewTests {

    // MARK: - Initialization Tests

    @Test
    func initializationWithDefaults() {
        let start = Date()
        let end = Date().addingTimeInterval(604800) // 7 days

        let review = WeeklyReview(weekStart: start, weekEnd: end)

        #expect(review.weekStart == start)
        #expect(review.weekEnd == end)
        #expect(review.conversationJSON == nil)
        #expect(review.wins.isEmpty)
        #expect(review.challenges.isEmpty)
        #expect(review.summary == nil)
        #expect(review.aiTakeaway == nil)
        #expect(review.isCompleted == false)
        #expect(review.completedAt == nil)
    }

    @Test
    func initializationWithAllParameters() {
        let id = UUID()
        let start = Date()
        let end = Date().addingTimeInterval(604800)
        let conversationData = Data("[]".utf8)
        let createdAt = Date()
        let completedAt = Date()

        let review = WeeklyReview(
            id: id,
            weekStart: start,
            weekEnd: end,
            conversationJSON: conversationData,
            wins: ["Win 1", "Win 2"],
            challenges: ["Challenge 1"],
            summary: "Good week",
            aiTakeaway: "Focus on rest",
            isCompleted: true,
            createdAt: createdAt,
            completedAt: completedAt
        )

        #expect(review.id == id)
        #expect(review.weekStart == start)
        #expect(review.weekEnd == end)
        #expect(review.conversationJSON == conversationData)
        #expect(review.wins.count == 2)
        #expect(review.challenges.count == 1)
        #expect(review.summary == "Good week")
        #expect(review.aiTakeaway == "Focus on rest")
        #expect(review.isCompleted == true)
        #expect(review.completedAt == completedAt)
    }

    // MARK: - conversations Computed Property Tests

    @Test
    func conversationsWithNilJSON() {
        let review = WeeklyReview(weekStart: Date(), weekEnd: Date())
        #expect(review.conversations.isEmpty)
    }

    @Test
    func conversationsWithInvalidJSON() {
        let review = WeeklyReview(
            weekStart: Date(),
            weekEnd: Date(),
            conversationJSON: Data("not valid json".utf8)
        )
        #expect(review.conversations.isEmpty, "Invalid JSON should return empty array")
    }

    @Test
    func conversationsWithEmptyArrayJSON() throws {
        let emptyArray: [ConversationMessage] = []
        let data = try JSONEncoder().encode(emptyArray)
        let review = WeeklyReview(weekStart: Date(), weekEnd: Date(), conversationJSON: data)
        #expect(review.conversations.isEmpty)
    }

    // MARK: - setConversations / conversations Round Trip

    @Test
    func setAndGetConversations() {
        let review = WeeklyReview(weekStart: Date(), weekEnd: Date())

        let messages = [
            ConversationMessage(role: .assistant, content: "How was your week?"),
            ConversationMessage(role: .user, content: "It was productive!"),
            ConversationMessage(role: .assistant, content: "What went well?")
        ]

        review.setConversations(messages)

        let retrieved = review.conversations
        #expect(retrieved.count == 3)
        #expect(retrieved[0].role == .assistant)
        #expect(retrieved[0].content == "How was your week?")
        #expect(retrieved[1].role == .user)
        #expect(retrieved[1].content == "It was productive!")
        #expect(retrieved[2].role == .assistant)
        #expect(retrieved[2].content == "What went well?")
    }

    @Test
    func setConversationsOverwritesPrevious() {
        let review = WeeklyReview(weekStart: Date(), weekEnd: Date())

        let initial = [ConversationMessage(role: .user, content: "First")]
        review.setConversations(initial)
        #expect(review.conversations.count == 1)

        let updated = [
            ConversationMessage(role: .user, content: "Second"),
            ConversationMessage(role: .assistant, content: "Third")
        ]
        review.setConversations(updated)
        #expect(review.conversations.count == 2)
        #expect(review.conversations[0].content == "Second")
    }

    @Test
    func setEmptyConversations() {
        let review = WeeklyReview(weekStart: Date(), weekEnd: Date())
        let messages = [ConversationMessage(role: .user, content: "Hello")]
        review.setConversations(messages)
        #expect(review.conversations.count == 1)

        review.setConversations([])
        #expect(review.conversations.isEmpty)
    }

    // MARK: - Wins and Challenges Tests

    @Test
    func winsAndChallengesDirectAssignment() {
        let review = WeeklyReview(weekStart: Date(), weekEnd: Date())

        review.wins = ["Shipped feature", "Good sleep"]
        review.challenges = ["Too many meetings"]

        #expect(review.wins.count == 2)
        #expect(review.wins[0] == "Shipped feature")
        #expect(review.challenges.count == 1)
        #expect(review.challenges[0] == "Too many meetings")
    }

    // MARK: - Unique ID Tests

    @Test
    func uniqueIDsGenerated() {
        let review1 = WeeklyReview(weekStart: Date(), weekEnd: Date())
        let review2 = WeeklyReview(weekStart: Date(), weekEnd: Date())
        #expect(review1.id != review2.id)
    }
}

// MARK: - ConversationMessage Tests

struct ConversationMessageTests {

    @Test
    func initializationWithDefaults() {
        let message = ConversationMessage(role: .user, content: "Hello")

        #expect(message.role == .user)
        #expect(message.content == "Hello")
    }

    @Test
    func initializationWithAllParameters() {
        let id = UUID()
        let timestamp = Date()

        let message = ConversationMessage(
            id: id,
            role: .assistant,
            content: "How can I help?",
            timestamp: timestamp
        )

        #expect(message.id == id)
        #expect(message.role == .assistant)
        #expect(message.content == "How can I help?")
        #expect(message.timestamp == timestamp)
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let original = ConversationMessage(role: .user, content: "Test message")
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ConversationMessage.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.role == original.role)
        #expect(decoded.content == original.content)
    }

    @Test
    func codableArrayRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let messages = [
            ConversationMessage(role: .assistant, content: "Hi"),
            ConversationMessage(role: .user, content: "Hello"),
        ]

        let data = try encoder.encode(messages)
        let decoded = try decoder.decode([ConversationMessage].self, from: data)

        #expect(decoded.count == 2)
        #expect(decoded[0].role == .assistant)
        #expect(decoded[1].role == .user)
    }

    @Test
    func uniqueIDsGenerated() {
        let msg1 = ConversationMessage(role: .user, content: "A")
        let msg2 = ConversationMessage(role: .user, content: "B")
        #expect(msg1.id != msg2.id)
    }
}

// MARK: - MessageRole Tests

struct MessageRoleTests {

    @Test
    func rawValues() {
        #expect(MessageRole.user.rawValue == "user")
        #expect(MessageRole.assistant.rawValue == "assistant")
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for role in [MessageRole.user, MessageRole.assistant] {
            let data = try encoder.encode(role)
            let decoded = try decoder.decode(MessageRole.self, from: data)
            #expect(decoded == role)
        }
    }

    @Test
    func decodableFromString() throws {
        let decoder = JSONDecoder()

        let data = Data("\"assistant\"".utf8)
        let decoded = try decoder.decode(MessageRole.self, from: data)
        #expect(decoded == .assistant)
    }

    @Test
    func decodableFailsForInvalidString() {
        let decoder = JSONDecoder()
        let invalidData = Data("\"system\"".utf8)

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(MessageRole.self, from: invalidData)
        }
    }
}

// MARK: - MonthlyReport Tests

struct MonthlyReportTests {

    // MARK: - Initialization Tests

    @Test
    func initializationWithDefaults() {
        let report = MonthlyReport(month: 2, year: 2026)

        #expect(report.month == 2)
        #expect(report.year == 2026)
        #expect(report.executiveSummary == nil)
        #expect(report.topInsight == nil)
        #expect(report.overallScore == nil)
        #expect(report.correlationsJSON == nil)
        #expect(report.isGenerated == false)
        #expect(report.generatedAt == nil)
    }

    @Test
    func initializationWithAllParameters() {
        let id = UUID()
        let createdAt = Date()
        let generatedAt = Date()
        let correlationsData = Data("[]".utf8)

        let report = MonthlyReport(
            id: id,
            month: 12,
            year: 2025,
            executiveSummary: "Strong month overall",
            topInsight: "Sleep correlates with focus",
            overallScore: 7.5,
            correlationsJSON: correlationsData,
            isGenerated: true,
            createdAt: createdAt,
            generatedAt: generatedAt
        )

        #expect(report.id == id)
        #expect(report.month == 12)
        #expect(report.year == 2025)
        #expect(report.executiveSummary == "Strong month overall")
        #expect(report.topInsight == "Sleep correlates with focus")
        #expect(report.overallScore == 7.5)
        #expect(report.correlationsJSON == correlationsData)
        #expect(report.isGenerated == true)
        #expect(report.createdAt == createdAt)
        #expect(report.generatedAt == generatedAt)
    }

    // MARK: - correlations Computed Property Tests

    @Test
    func correlationsWithNilJSON() {
        let report = MonthlyReport(month: 1, year: 2026)
        #expect(report.correlations.isEmpty)
    }

    @Test
    func correlationsWithInvalidJSON() {
        let report = MonthlyReport(
            month: 1,
            year: 2026,
            correlationsJSON: Data("invalid".utf8)
        )
        #expect(report.correlations.isEmpty, "Invalid JSON should return empty array")
    }

    @Test
    func correlationsWithEmptyArrayJSON() throws {
        let emptyArray: [Correlation] = []
        let data = try JSONEncoder().encode(emptyArray)
        let report = MonthlyReport(month: 1, year: 2026, correlationsJSON: data)
        #expect(report.correlations.isEmpty)
    }

    // MARK: - setCorrelations / correlations Round Trip

    @Test
    func setAndGetCorrelations() {
        let report = MonthlyReport(month: 2, year: 2026)

        let correlations = [
            Correlation(
                factor1: "Sleep",
                factor2: "Focus",
                coefficient: 0.72,
                description: "Better sleep leads to better focus"
            ),
            Correlation(
                factor1: "Exercise",
                factor2: "Energy",
                coefficient: 0.65,
                description: "More exercise increases energy"
            )
        ]

        report.setCorrelations(correlations)

        let retrieved = report.correlations
        #expect(retrieved.count == 2)
        #expect(retrieved[0].factor1 == "Sleep")
        #expect(retrieved[0].factor2 == "Focus")
        #expect(retrieved[0].coefficient == 0.72)
        #expect(retrieved[0].description == "Better sleep leads to better focus")
        #expect(retrieved[1].factor1 == "Exercise")
        #expect(retrieved[1].coefficient == 0.65)
    }

    @Test
    func setCorrelationsOverwritesPrevious() {
        let report = MonthlyReport(month: 1, year: 2026)

        let initial = [
            Correlation(factor1: "A", factor2: "B", coefficient: 0.5, description: "AB")
        ]
        report.setCorrelations(initial)
        #expect(report.correlations.count == 1)

        let updated = [
            Correlation(factor1: "C", factor2: "D", coefficient: 0.3, description: "CD"),
            Correlation(factor1: "E", factor2: "F", coefficient: -0.4, description: "EF")
        ]
        report.setCorrelations(updated)
        #expect(report.correlations.count == 2)
        #expect(report.correlations[0].factor1 == "C")
    }

    @Test
    func setEmptyCorrelations() {
        let report = MonthlyReport(month: 1, year: 2026)
        let initial = [
            Correlation(factor1: "X", factor2: "Y", coefficient: 0.1, description: "XY")
        ]
        report.setCorrelations(initial)
        #expect(report.correlations.count == 1)

        report.setCorrelations([])
        #expect(report.correlations.isEmpty)
    }

    // MARK: - Unique ID Tests

    @Test
    func uniqueIDsGenerated() {
        let report1 = MonthlyReport(month: 1, year: 2026)
        let report2 = MonthlyReport(month: 2, year: 2026)
        #expect(report1.id != report2.id)
    }
}

// MARK: - Correlation Tests

struct CorrelationTests {

    @Test
    func initializationWithDefaults() {
        let correlation = Correlation(
            factor1: "Sleep",
            factor2: "Focus",
            coefficient: 0.72,
            description: "Sleep improves focus"
        )

        #expect(correlation.factor1 == "Sleep")
        #expect(correlation.factor2 == "Focus")
        #expect(correlation.coefficient == 0.72)
        #expect(correlation.description == "Sleep improves focus")
    }

    @Test
    func initializationWithCustomID() {
        let id = UUID()
        let correlation = Correlation(
            id: id,
            factor1: "A",
            factor2: "B",
            coefficient: -0.5,
            description: "Inverse relationship"
        )
        #expect(correlation.id == id)
    }

    @Test
    func negativeCoefficient() {
        let correlation = Correlation(
            factor1: "Screen Time",
            factor2: "Sleep",
            coefficient: -0.68,
            description: "More screen time reduces sleep"
        )
        #expect(correlation.coefficient < 0)
        #expect(correlation.coefficient == -0.68)
    }

    @Test
    func zeroCoefficient() {
        let correlation = Correlation(
            factor1: "Steps",
            factor2: "Growth",
            coefficient: 0.0,
            description: "No correlation"
        )
        #expect(correlation.coefficient == 0.0)
    }

    @Test
    func extremeCoefficients() {
        let perfect = Correlation(
            factor1: "A",
            factor2: "B",
            coefficient: 1.0,
            description: "Perfect positive"
        )
        let inversePerfect = Correlation(
            factor1: "C",
            factor2: "D",
            coefficient: -1.0,
            description: "Perfect negative"
        )
        #expect(perfect.coefficient == 1.0)
        #expect(inversePerfect.coefficient == -1.0)
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let original = Correlation(
            factor1: "Sleep",
            factor2: "Energy",
            coefficient: 0.85,
            description: "Strong positive"
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Correlation.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.factor1 == original.factor1)
        #expect(decoded.factor2 == original.factor2)
        #expect(decoded.coefficient == original.coefficient)
        #expect(decoded.description == original.description)
    }

    @Test
    func codableArrayRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let correlations = [
            Correlation(factor1: "A", factor2: "B", coefficient: 0.5, description: "AB"),
            Correlation(factor1: "C", factor2: "D", coefficient: -0.3, description: "CD"),
        ]

        let data = try encoder.encode(correlations)
        let decoded = try decoder.decode([Correlation].self, from: data)

        #expect(decoded.count == 2)
        #expect(decoded[0].factor1 == "A")
        #expect(decoded[1].coefficient == -0.3)
    }

    @Test
    func uniqueIDsGenerated() {
        let c1 = Correlation(factor1: "A", factor2: "B", coefficient: 0.1, description: "AB")
        let c2 = Correlation(factor1: "A", factor2: "B", coefficient: 0.1, description: "AB")
        #expect(c1.id != c2.id)
    }
}

// MARK: - DimensionType Tests

struct DimensionTypeTests {

    @Test
    func labels() {
        #expect(DimensionType.energy.label == "Energy")
        #expect(DimensionType.focus.label == "Focus")
        // The 4th axis is reframed to Calm (enum case + rawValue stay "stress").
        #expect(DimensionType.stress.label == "Calm")
        #expect(DimensionType.growth.label == "Growth")
    }

    @Test
    func icons() {
        #expect(DimensionType.energy.icon == "sun.max.fill")
        #expect(DimensionType.focus.icon == "scope")
        #expect(DimensionType.stress.icon == "wind")
        #expect(DimensionType.growth.icon == "leaf.fill")
    }

    @Test
    func caseIterable() {
        let allCases = DimensionType.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.energy))
        #expect(allCases.contains(.focus))
        #expect(allCases.contains(.stress))
        #expect(allCases.contains(.growth))
    }

    @Test
    func rawValues() {
        #expect(DimensionType.energy.rawValue == "energy")
        #expect(DimensionType.focus.rawValue == "focus")
        #expect(DimensionType.stress.rawValue == "stress")
        #expect(DimensionType.growth.rawValue == "growth")
    }

    @Test
    func identifiable() {
        #expect(DimensionType.energy.id == "energy")
        #expect(DimensionType.focus.id == "focus")
        #expect(DimensionType.stress.id == "stress")
        #expect(DimensionType.growth.id == "growth")
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for dimension in DimensionType.allCases {
            let data = try encoder.encode(dimension)
            let decoded = try decoder.decode(DimensionType.self, from: data)
            #expect(decoded == dimension)
        }
    }

    @Test
    func decodableFromString() throws {
        let decoder = JSONDecoder()

        let data = Data("\"stress\"".utf8)
        let decoded = try decoder.decode(DimensionType.self, from: data)
        #expect(decoded == .stress)
    }

    @Test
    func decodableFailsForInvalidString() {
        let decoder = JSONDecoder()
        let invalidData = Data("\"happiness\"".utf8)

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(DimensionType.self, from: invalidData)
        }
    }

    @Test
    func questionIsNotEmpty() {
        // LocalizedStringKey does not easily expose its string,
        // so we just verify each dimension has a question defined by calling it.
        for dimension in DimensionType.allCases {
            _ = dimension.question
        }
    }
}

// MARK: - Cross-Model Integration Tests

struct CrossModelIntegrationTests {

    @Test
    func dailyCheckInCompositeScoreRange() {
        // Verify composite score is always in valid range [1.0, 5.0]
        for energy in [1, 3, 5] {
            for focus in [1, 3, 5] {
                for stress in [1, 3, 5] {
                    for growth in [1, 3, 5] {
                        let checkIn = DailyCheckIn(
                            energyScore: energy,
                            focusScore: focus,
                            stressScore: stress,
                            growthScore: growth
                        )
                        #expect(checkIn.compositeScore >= 1.0)
                        #expect(checkIn.compositeScore <= 5.0)
                    }
                }
            }
        }
    }

    @Test
    func actionItemV2AllSourcesWork() {
        for source in ActionSource.allCases {
            let action = ActionItemV2(text: "Test", source: source)
            #expect(action.source == source)
        }
    }

    @Test
    func actionItemV2AllPrioritiesWork() {
        for priority in ActionPriority.allCases {
            let action = ActionItemV2(text: "Test", priority: priority)
            #expect(action.priority == priority)
        }
    }

    @Test
    func dailyCheckInSetScoreForAllDimensions() {
        let checkIn = DailyCheckIn()

        for dimension in DimensionType.allCases {
            checkIn.setScore(4, for: dimension)
            #expect(checkIn.score(for: dimension) == 4)
        }
    }

    @Test
    func weeklyReviewConversationPreservesMessageOrder() {
        let review = WeeklyReview(weekStart: Date(), weekEnd: Date())

        let messages = (0..<10).map { i in
            ConversationMessage(
                role: i.isMultiple(of: 2) ? .assistant : .user,
                content: "Message \(i)"
            )
        }

        review.setConversations(messages)
        let retrieved = review.conversations

        #expect(retrieved.count == 10)
        for i in 0..<10 {
            #expect(retrieved[i].content == "Message \(i)")
        }
    }

    @Test
    func monthlyReportCorrelationPreservesCoefficients() {
        let report = MonthlyReport(month: 1, year: 2026)

        let correlations = [
            Correlation(factor1: "A", factor2: "B", coefficient: -0.99, description: "Strong negative"),
            Correlation(factor1: "C", factor2: "D", coefficient: 0.01, description: "Weak positive"),
            Correlation(factor1: "E", factor2: "F", coefficient: 0.0, description: "None"),
        ]

        report.setCorrelations(correlations)
        let retrieved = report.correlations

        #expect(retrieved[0].coefficient == -0.99)
        #expect(retrieved[1].coefficient == 0.01)
        #expect(retrieved[2].coefficient == 0.0)
    }

    @Test
    func streakFullLifecycle() {
        let streak = Streak()
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())

        // Start fresh
        #expect(streak.isActiveToday == false)
        #expect(streak.currentStreak == 0)

        // Day 1
        streak.recordCheckIn(on: base)
        #expect(streak.currentStreak == 1)
        #expect(streak.totalCheckIns == 1)

        // Day 2 (consecutive)
        let day2 = calendar.date(byAdding: .day, value: 1, to: base)!
        streak.recordCheckIn(on: day2)
        #expect(streak.currentStreak == 2)

        // Day 3 (consecutive)
        let day3 = calendar.date(byAdding: .day, value: 2, to: base)!
        streak.recordCheckIn(on: day3)
        #expect(streak.currentStreak == 3)
        #expect(streak.longestStreak == 3)

        // Day 3 again (no-op)
        streak.recordCheckIn(on: day3)
        #expect(streak.currentStreak == 3)
        #expect(streak.totalCheckIns == 3, "Duplicate should not increment total")

        // Day 6 (gap of 2 days)
        let day6 = calendar.date(byAdding: .day, value: 5, to: base)!
        streak.recordCheckIn(on: day6)
        #expect(streak.currentStreak == 1, "Gap should reset streak")
        #expect(streak.longestStreak == 3, "Longest streak preserved")
        #expect(streak.totalCheckIns == 4)
    }
}
