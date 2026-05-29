//
//  StreakRecomputeTests.swift
//  agile-selfTests
//
//  Pins Streak.recomputeFromHistory — the authoritative path that now drives every phone
//  save (today-first, edit, back-fill) and delete. The older incremental recordCheckIn(on:)
//  is covered elsewhere; this suite locks the recompute branches that incremental logic can't
//  express: gap-bridging back-fill, an honest longestStreak that can decrease, the
//  "current run is live only if the latest day is today or yesterday" gate, distinct-day
//  totalCheckIns, and the empty-history reset. `asOf` is injected so "today" is deterministic.
//

import Testing
import Foundation
@testable import agile_self

@Suite("Streak recompute from history")
struct StreakRecomputeTests {

    private let cal = Calendar.current
    /// Fixed reference "today" (mid-May, away from DST boundaries) so the today/yesterday
    /// liveness window is deterministic regardless of wall-clock.
    private let asOf = Calendar.current.date(
        from: DateComponents(year: 2026, month: 5, day: 15, hour: 12)
    )!

    /// A start-of-day date `offset` days from `asOf` (0 = today, -1 = yesterday).
    private func day(_ offset: Int) -> Date {
        cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: asOf))!
    }

    @Test("Empty history resets every statistic")
    func emptyHistoryResets() {
        let streak = Streak(currentStreak: 9, longestStreak: 12,
                            lastCheckInDate: Date(), totalCheckIns: 50)
        streak.recomputeFromHistory(checkInDates: [], asOf: asOf)
        #expect(streak.currentStreak == 0)
        #expect(streak.longestStreak == 0)
        #expect(streak.totalCheckIns == 0)
        #expect(streak.lastCheckInDate == nil)
    }

    @Test("A single check-in today is a streak of one")
    func singleToday() {
        let streak = Streak()
        streak.recomputeFromHistory(checkInDates: [day(0)], asOf: asOf)
        #expect(streak.currentStreak == 1)
        #expect(streak.longestStreak == 1)
        #expect(streak.totalCheckIns == 1)
        #expect(streak.lastCheckInDate == day(0))
    }

    @Test("Most recent == yesterday keeps the current streak live")
    func yesterdayIsStillLive() {
        let streak = Streak()
        streak.recomputeFromHistory(checkInDates: [day(-2), day(-1)], asOf: asOf)
        #expect(streak.currentStreak == 2)
        #expect(streak.longestStreak == 2)
    }

    @Test("Most recent older than yesterday breaks the current streak (longest survives)")
    func staleRunBreaksCurrent() {
        let streak = Streak()
        streak.recomputeFromHistory(checkInDates: [day(-3), day(-2)], asOf: asOf)
        #expect(streak.currentStreak == 0)   // latest is 2 days ago → not live
        #expect(streak.longestStreak == 2)   // the run still counts toward longest
        #expect(streak.totalCheckIns == 2)
    }

    @Test("A consecutive run ending today counts fully")
    func consecutiveRunEndingToday() {
        let streak = Streak()
        let dates = (0...4).map { day(-$0) }   // today … 4 days ago
        streak.recomputeFromHistory(checkInDates: dates, asOf: asOf)
        #expect(streak.currentStreak == 5)
        #expect(streak.longestStreak == 5)
        #expect(streak.totalCheckIns == 5)
    }

    @Test("Back-filling a missing day bridges two runs into one")
    func backfillBridgesGap() {
        let streak = Streak()
        // Gap at day(-2): two runs, [-4,-3] and [-1,0].
        let withGap = [day(-4), day(-3), day(-1), day(0)]
        streak.recomputeFromHistory(checkInDates: withGap, asOf: asOf)
        #expect(streak.currentStreak == 2)   // only [-1, 0]
        #expect(streak.longestStreak == 2)

        // Back-fill day(-2) → a single 5-day run ending today.
        let bridged = withGap + [day(-2)]
        streak.recomputeFromHistory(checkInDates: bridged, asOf: asOf)
        #expect(streak.currentStreak == 5)
        #expect(streak.longestStreak == 5)
        #expect(streak.totalCheckIns == 5)
    }

    @Test("Deleting a middle day honestly shrinks the longest streak")
    func deletionShrinksLongest() {
        let streak = Streak(longestStreak: 99)   // stale, inflated by the old incremental path
        let fiveRun = (0...4).map { day(-$0) }
        streak.recomputeFromHistory(checkInDates: fiveRun, asOf: asOf)
        #expect(streak.longestStreak == 5)       // recomputed down from 99

        // Remove the middle day(-2): runs [-4,-3]=2 and [-1,0]=2.
        let broken = [day(0), day(-1), day(-3), day(-4)]
        streak.recomputeFromHistory(checkInDates: broken, asOf: asOf)
        #expect(streak.currentStreak == 2)
        #expect(streak.longestStreak == 2)
        #expect(streak.totalCheckIns == 4)
    }

    @Test("Duplicate dates collapse to distinct days")
    func duplicateDatesDeduped() {
        let streak = Streak()
        streak.recomputeFromHistory(
            checkInDates: [day(0), day(0), day(-1), day(-1)],
            asOf: asOf
        )
        #expect(streak.totalCheckIns == 2)
        #expect(streak.currentStreak == 2)
    }

    @Test("Longest counts a past run even when the current run is shorter")
    func longestCountsAwayFromToday() {
        let streak = Streak()
        // A 4-day run far in the past + a lone check-in today.
        let dates = [day(-13), day(-12), day(-11), day(-10), day(0)]
        streak.recomputeFromHistory(checkInDates: dates, asOf: asOf)
        #expect(streak.currentStreak == 1)   // only today is live
        #expect(streak.longestStreak == 4)   // the old run
        #expect(streak.totalCheckIns == 5)
    }
}
