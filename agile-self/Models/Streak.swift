//
//  Streak.swift
//  agile-self
//
//  Created by Claude on 2026/02/22.
//

import Foundation
import SwiftData

/// Tracks the user's daily check-in streak and lifetime statistics.
/// There should only ever be one Streak record in the database.
@Model
final class Streak {

    // MARK: - Persisted Properties

    @Attribute(.unique) var id: UUID
    /// Number of consecutive days with a check-in ending today (or yesterday if today is pending).
    var currentStreak: Int
    /// All-time longest consecutive check-in streak.
    var longestStreak: Int
    /// The calendar date of the most recent check-in.
    var lastCheckInDate: Date?
    /// Lifetime total number of check-ins recorded.
    var totalCheckIns: Int
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCheckInDate: Date? = nil,
        totalCheckIns: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCheckInDate = lastCheckInDate
        self.totalCheckIns = totalCheckIns
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// Returns true if the user has already checked in today.
    var isActiveToday: Bool {
        guard let last = lastCheckInDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Methods

    /// Records a check-in on the given date and updates streak logic.
    ///
    /// - If the date is the same day as the last check-in, this is a no-op (already counted).
    /// - If the date is exactly one day after the last check-in, the streak continues.
    /// - Otherwise the streak resets to 1.
    func recordCheckIn(on date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let last = lastCheckInDate {
            let lastDay = calendar.startOfDay(for: last)

            // Same day -- already counted
            if calendar.isDate(today, inSameDayAs: lastDay) {
                return
            }

            // Consecutive day -- extend streak
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDay),
               calendar.isDate(today, inSameDayAs: nextDay) {
                currentStreak += 1
            } else {
                // Gap detected -- reset streak
                currentStreak = 1
            }
        } else {
            // First ever check-in
            currentStreak = 1
        }

        totalCheckIns += 1
        lastCheckInDate = today

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    /// Rebuilds every streak statistic from the full set of check-in dates.
    ///
    /// This is the authoritative path for any write that changes *which days exist* —
    /// back-filling a missed day, deleting an entry, or an edit that adds/removes a day.
    /// The incremental `recordCheckIn(on:)` only understands today-relative transitions, so it
    /// cannot bridge a newly-filled gap or re-derive the streak after a deletion; this scan can.
    ///
    /// - `totalCheckIns` = number of distinct days with a check-in.
    /// - `longestStreak` = longest run of consecutive days anywhere in history.
    /// - `currentStreak` = the run ending on the most recent day, but only when that day is
    ///   today or yesterday (otherwise the current run is broken → 0). This matches the prior
    ///   "ending today (or yesterday if today is pending)" semantics. Because it recomputes
    ///   honestly, `longestStreak` can legitimately *decrease* if check-ins are deleted.
    ///
    /// - Parameters:
    ///   - checkInDates: every check-in's `date` (need not be unique or sorted).
    ///   - now: the reference "today" (injectable for testing).
    func recomputeFromHistory(checkInDates: [Date], asOf now: Date = Date()) {
        let calendar = Calendar.current
        let days = Set(checkInDates.map { calendar.startOfDay(for: $0) }).sorted()

        totalCheckIns = days.count

        guard let mostRecent = days.last else {
            currentStreak = 0
            longestStreak = 0
            lastCheckInDate = nil
            return
        }
        lastCheckInDate = mostRecent

        // Longest consecutive run anywhere in the history.
        var longest = 1
        var run = 1
        for index in 1..<days.count {
            let prevDay = days[index - 1]
            let curDay = days[index]
            if let next = calendar.date(byAdding: .day, value: 1, to: prevDay),
               calendar.isDate(curDay, inSameDayAs: next) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        longestStreak = longest

        // The current run is only "live" if the most recent check-in is today or yesterday.
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let isLive = calendar.isDate(mostRecent, inSameDayAs: today)
            || (yesterday.map { calendar.isDate(mostRecent, inSameDayAs: $0) } ?? false)
        guard isLive else {
            currentStreak = 0
            return
        }

        // Count consecutive days backward from the most recent.
        var current = 1
        var index = days.count - 1
        while index > 0 {
            let prevDay = days[index - 1]
            let curDay = days[index]
            if let next = calendar.date(byAdding: .day, value: 1, to: prevDay),
               calendar.isDate(curDay, inSameDayAs: next) {
                current += 1
                index -= 1
            } else {
                break
            }
        }
        currentStreak = current
    }
}
