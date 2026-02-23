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
}
