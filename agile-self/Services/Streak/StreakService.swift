//
//  StreakService.swift
//  agile-self
//
//  Service layer for managing check-in streaks via SwiftData.
//

import Foundation
import SwiftData

/// Manages the user's check-in streak, ensuring a single Streak record exists in the database.
final class StreakService {

    // MARK: - Record Check-In

    /// Records a check-in for today and updates the streak.
    /// Creates the Streak record if it does not yet exist.
    func recordCheckIn(context: ModelContext) {
        let streak = fetchOrCreateStreak(context: context)
        streak.recordCheckIn()
    }

    // MARK: - Get or Create Streak

    /// Fetches the existing Streak record or creates a new one if none exists.
    /// The Streak model is treated as a singleton in the database.
    func fetchOrCreateStreak(context: ModelContext) -> Streak {
        let descriptor = FetchDescriptor<Streak>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let newStreak = Streak()
        context.insert(newStreak)
        return newStreak
    }
}
