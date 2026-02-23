//
//  UserProfile.swift
//  agile-self
//
//  Created by Claude on 2026/02/22.
//

import Foundation
import SwiftData

// MARK: - Supporting Types (must be top-level, not nested inside @Model)

/// The user's subscription level.
enum SubscriptionTier: String, Codable, CaseIterable {
    /// Free tier with basic features.
    case free
    /// Premium tier with AI insights, correlations, and cloud AI.
    case premium
}

// MARK: - UserProfile Model

/// Singleton-style profile storing user preferences and subscription state.
/// There should only ever be one UserProfile record in the database.
@Model
final class UserProfile {

    // MARK: - Persisted Properties

    @Attribute(.unique) var id: UUID
    /// Optional display name for personalisation.
    var displayName: String?
    /// Hour component (0-23) for the daily check-in reminder. Default: 21 (9 PM).
    var checkInReminderHour: Int
    /// Minute component (0-59) for the daily check-in reminder. Default: 0.
    var checkInReminderMinute: Int
    /// Day of week for the weekly review prompt. 1 = Sunday, 7 = Saturday. Default: 6 (Friday).
    var weeklyReviewDay: Int
    /// Current subscription tier.
    var subscriptionTier: SubscriptionTier
    /// Whether the user has opted in to cloud-based AI processing.
    var allowCloudAI: Bool
    /// Whether the user has enabled push notifications for reminders.
    var notificationsEnabled: Bool
    /// Whether the user has completed the onboarding flow.
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        displayName: String? = nil,
        checkInReminderHour: Int = 21,
        checkInReminderMinute: Int = 0,
        weeklyReviewDay: Int = 6,
        subscriptionTier: SubscriptionTier = .free,
        allowCloudAI: Bool = false,
        notificationsEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.checkInReminderHour = checkInReminderHour
        self.checkInReminderMinute = checkInReminderMinute
        self.weeklyReviewDay = weeklyReviewDay
        self.subscriptionTier = subscriptionTier
        self.allowCloudAI = allowCloudAI
        self.notificationsEnabled = notificationsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
    }
}
