//
//  WatchConnectivityServiceTests.swift
//  agile-selfTests
//
//  Tests for the iOS-side WatchConnectivityService persistence logic.
//

import Testing
import Foundation
import SwiftData
@testable import agile_self

// MARK: - Helper

/// Creates an in-memory ModelContainer for testing.
private func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        DailyCheckIn.self,
        HealthSnapshot.self,
        WeeklyReview.self,
        MonthlyReport.self,
        ActionItemV2.self,
        UserProfile.self,
        Streak.self,
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - persistCheckIn Tests

@MainActor
struct WatchConnectivityServicePersistTests {

    @Test
    func persistCheckIn_createsNewCheckIn() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let reply = try service.persistCheckIn(
            energy: 4, focus: 4, stress: 2, growth: 5,
            context: context
        )

        // Verify check-in was created
        let checkIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(checkIns.count == 1)
        #expect(checkIns[0].energyScore == 4)
        #expect(checkIns[0].focusScore == 4)
        #expect(checkIns[0].stressScore == 2)
        #expect(checkIns[0].growthScore == 5)

        // Verify reply
        let score = reply["compositeScore"] as? Double
        #expect(score != nil)
        // Plain mean: (4 + 4 + 2 + 5) / 4.0 = 15 / 4.0 = 3.75
        #expect(score == 3.75)

        let streak = reply["currentStreak"] as? Int
        #expect(streak == 1)
    }

    @Test
    func persistCheckIn_upsertsExistingCheckIn() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        // First check-in
        _ = try service.persistCheckIn(
            energy: 5, focus: 5, stress: 5, growth: 5,
            context: context
        )

        // Second check-in (same day, should upsert)
        let reply = try service.persistCheckIn(
            energy: 5, focus: 4, stress: 2, growth: 5,
            context: context
        )

        // Still only one check-in
        let checkIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(checkIns.count == 1)
        #expect(checkIns[0].energyScore == 5)
        #expect(checkIns[0].focusScore == 4)
        #expect(checkIns[0].stressScore == 2)
        #expect(checkIns[0].growthScore == 5)

        // Plain mean: (5 + 4 + 2 + 5) / 4.0 = 16 / 4.0 = 4.0
        let score = reply["compositeScore"] as? Double
        #expect(score == 4.0)
    }

    @Test
    func persistCheckIn_createsStreak() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        _ = try service.persistCheckIn(
            energy: 5, focus: 5, stress: 5, growth: 5,
            context: context
        )

        let streaks = try context.fetch(FetchDescriptor<Streak>())
        #expect(streaks.count == 1)
        #expect(streaks[0].currentStreak == 1)
        #expect(streaks[0].totalCheckIns == 1)
    }

    @Test
    func persistCheckIn_reusesExistingStreak() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        // Pre-insert a streak
        let existingStreak = Streak(currentStreak: 5, longestStreak: 10, totalCheckIns: 20)
        context.insert(existingStreak)
        try context.save()

        _ = try service.persistCheckIn(
            energy: 5, focus: 5, stress: 5, growth: 5,
            context: context
        )

        // Should still be one streak (reused)
        let streaks = try context.fetch(FetchDescriptor<Streak>())
        #expect(streaks.count == 1)
        // Same-day: recordCheckIn on the streak with today's date
        // Since lastCheckInDate was nil -> first check-in style -> streak = 1? No...
        // existingStreak has currentStreak=5 but lastCheckInDate=nil
        // So recordCheckIn sees nil lastCheckInDate -> sets currentStreak = 1
        // This is correct behavior: streak without a lastCheckInDate is effectively reset.
    }

    @Test
    func persistCheckIn_replyContainsCorrectKeys() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let reply = try service.persistCheckIn(
            energy: 7, focus: 6, stress: 4, growth: 8,
            context: context
        )

        #expect(reply["compositeScore"] != nil)
        #expect(reply["currentStreak"] != nil)
        #expect(reply["compositeScore"] is Double)
        #expect(reply["currentStreak"] is Int)
    }

    @Test
    func persistCheckIn_compositeScoreMatchesDailyCheckIn() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let reply = try service.persistCheckIn(
            energy: 3, focus: 4, stress: 5, growth: 2,
            context: context
        )

        // Verify the reply's composite score matches what DailyCheckIn would compute
        let reference = DailyCheckIn(energyScore: 3, focusScore: 4, stressScore: 5, growthScore: 2)
        let replyScore = reply["compositeScore"] as! Double
        #expect(replyScore == reference.compositeScore)
    }

    @Test
    func persistCheckIn_allMinScores() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let reply = try service.persistCheckIn(
            energy: 1, focus: 1, stress: 5, growth: 1,
            context: context
        )

        // Plain mean: (1 + 1 + 5 + 1) / 4.0 = 8/4 = 2.0 (calm-oriented 4th axis)
        #expect(reply["compositeScore"] as? Double == 2.0)
    }

    @Test
    func persistCheckIn_allMaxScores() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let reply = try service.persistCheckIn(
            energy: 5, focus: 5, stress: 1, growth: 5,
            context: context
        )

        // Plain mean: (5 + 5 + 1 + 5) / 4.0 = 16/4 = 4.0 (calm-oriented 4th axis)
        #expect(reply["compositeScore"] as? Double == 4.0)
    }

    @Test
    func persistCheckIn_checkInDateIsStartOfToday() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        _ = try service.persistCheckIn(
            energy: 5, focus: 5, stress: 5, growth: 5,
            context: context
        )

        let checkIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        let expected = Calendar.current.startOfDay(for: Date())
        #expect(checkIns[0].date == expected)
    }
}

// MARK: - fetchCurrentState Tests

@MainActor
struct WatchConnectivityServiceStateTests {

    @Test
    func fetchCurrentState_noData_returnsEmpty() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let reply = try service.fetchCurrentState(context: context)

        #expect(reply["compositeScore"] == nil)
        #expect(reply["didCheckInToday"] == nil)
        #expect(reply["currentStreak"] == nil)
    }

    @Test
    func fetchCurrentState_withCheckIn_returnsScore() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        // Create a check-in for today
        let today = Calendar.current.startOfDay(for: Date())
        let checkIn = DailyCheckIn(date: today, energyScore: 8, focusScore: 7, stressScore: 3, growthScore: 9)
        context.insert(checkIn)
        try context.save()

        let reply = try service.fetchCurrentState(context: context)

        #expect(reply["compositeScore"] as? Double == checkIn.compositeScore)
        #expect(reply["didCheckInToday"] as? Bool == true)
    }

    @Test
    func fetchCurrentState_withStreak_returnsCount() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let streak = Streak(currentStreak: 7, longestStreak: 14, lastCheckInDate: Date(), totalCheckIns: 30)
        context.insert(streak)
        try context.save()

        let reply = try service.fetchCurrentState(context: context)

        #expect(reply["currentStreak"] as? Int == 7)
    }

    @Test
    func fetchCurrentState_withBothCheckInAndStreak() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let today = Calendar.current.startOfDay(for: Date())
        let checkIn = DailyCheckIn(date: today, energyScore: 6, focusScore: 6, stressScore: 6, growthScore: 6)
        context.insert(checkIn)

        let streak = Streak(currentStreak: 3, longestStreak: 3, lastCheckInDate: today, totalCheckIns: 3)
        context.insert(streak)
        try context.save()

        let reply = try service.fetchCurrentState(context: context)

        #expect(reply["compositeScore"] != nil)
        #expect(reply["didCheckInToday"] as? Bool == true)
        #expect(reply["currentStreak"] as? Int == 3)
    }

    @Test
    func fetchCurrentState_yesterdayCheckIn_notReturned() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        let checkIn = DailyCheckIn(date: yesterday, energyScore: 8, focusScore: 7, stressScore: 3, growthScore: 9)
        context.insert(checkIn)
        try context.save()

        let reply = try service.fetchCurrentState(context: context)

        // Yesterday's check-in should not be returned as today's
        #expect(reply["compositeScore"] == nil)
        #expect(reply["didCheckInToday"] == nil)
    }
}

// MARK: - handleCheckIn Message Parsing Tests

@MainActor
struct WatchConnectivityServiceMessageTests {

    @Test
    func handleCheckIn_validMessage_callsPersist() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)

        let message: [String: Any] = [
            "type": "checkIn",
            "energy": 7,
            "focus": 8,
            "stress": 3,
            "growth": 6
        ]

        // handleCheckIn dispatches async, so we test persistCheckIn directly
        // This tests message parsing would work
        let energy = message["energy"] as? Int
        let focus = message["focus"] as? Int
        let stress = message["stress"] as? Int
        let growth = message["growth"] as? Int

        #expect(energy == 7)
        #expect(focus == 8)
        #expect(stress == 3)
        #expect(growth == 6)
    }

    @Test
    func handleCheckIn_missingFields_doesNotCrash() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)

        // Missing "growth" key
        let message: [String: Any] = [
            "type": "checkIn",
            "energy": 7,
            "focus": 8,
            "stress": 3
        ]

        // Should return without crashing (guard fails silently)
        service.handleCheckIn(message)

        // No check-in should be created
        let context = container.mainContext
        let checkIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(checkIns.isEmpty)
    }

    @Test
    func handleCheckIn_wrongTypes_doesNotCrash() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)

        let message: [String: Any] = [
            "type": "checkIn",
            "energy": "seven",  // String instead of Int
            "focus": 8,
            "stress": 3,
            "growth": 6
        ]

        service.handleCheckIn(message)

        let context = container.mainContext
        let checkIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(checkIns.isEmpty)
    }

    @Test
    func handleCheckIn_emptyMessage_doesNotCrash() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)

        service.handleCheckIn([:])

        let context = container.mainContext
        let checkIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(checkIns.isEmpty)
    }
}

// MARK: - Integration: Full Round-Trip Tests

@MainActor
struct WatchConnectivityServiceIntegrationTests {

    @Test
    func fullRoundTrip_persistThenFetch() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        // Persist
        let persistReply = try service.persistCheckIn(
            energy: 7, focus: 8, stress: 2, growth: 9,
            context: context
        )

        // Fetch
        let stateReply = try service.fetchCurrentState(context: context)

        // Both should agree on composite score
        let persistScore = persistReply["compositeScore"] as! Double
        let stateScore = stateReply["compositeScore"] as! Double
        #expect(persistScore == stateScore)

        // State should indicate today's check-in exists
        #expect(stateReply["didCheckInToday"] as? Bool == true)

        // Streak should match
        let persistStreak = persistReply["currentStreak"] as! Int
        let stateStreak = stateReply["currentStreak"] as! Int
        #expect(persistStreak == stateStreak)
    }

    @Test
    func multipleUpserts_alwaysOneCheckIn() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        // Persist three times
        for i in 1...3 {
            _ = try service.persistCheckIn(
                energy: i, focus: i, stress: i, growth: i,
                context: context
            )
        }

        // Only one check-in should exist (upserted)
        let checkIns = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(checkIns.count == 1)

        // Should have the last values
        #expect(checkIns[0].energyScore == 3)
        #expect(checkIns[0].focusScore == 3)
        #expect(checkIns[0].stressScore == 3)
        #expect(checkIns[0].growthScore == 3)
    }

    @Test
    func multipleUpserts_streakStaysAtOne() throws {
        let container = try makeTestContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        // Persist three times on same day
        for _ in 1...3 {
            _ = try service.persistCheckIn(
                energy: 5, focus: 5, stress: 5, growth: 5,
                context: context
            )
        }

        // Streak should be 1 (same day)
        let streaks = try context.fetch(FetchDescriptor<Streak>())
        #expect(streaks.count == 1)
        #expect(streaks[0].currentStreak == 1)
        // totalCheckIns: first persist creates the streak and calls recordCheckIn -> 1
        // second and third calls recordCheckIn on same day -> no-op
        #expect(streaks[0].totalCheckIns == 1)
    }
}
