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

    /// Authoritatively rebuilds the streak from the full check-in history.
    ///
    /// Use this after any write that can change which days exist — back-filling a missed day,
    /// editing/deleting a past day — because the incremental `recordCheckIn` only handles
    /// today-relative transitions. Safe (and idempotent) to call after an ordinary same-day
    /// check-in too, so callers don't have to special-case "is this today or the past".
    ///
    /// NOTE: callers should `save()` any pending insert/delete *before* calling this, so the
    /// history fetch reflects the change.
    @discardableResult
    func recompute(context: ModelContext) -> Streak {
        let streak = fetchOrCreateStreak(context: context)
        let descriptor = FetchDescriptor<DailyCheckIn>(sortBy: [SortDescriptor(\.date, order: .forward)])
        let dates = ((try? context.fetch(descriptor)) ?? []).map(\.date)
        streak.recomputeFromHistory(checkInDates: dates)
        return streak
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
