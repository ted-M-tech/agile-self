//
//  NotificationService.swift
//  agile-self
//
//  Smart notification scheduling for daily check-in reminders.
//

import Foundation
import UserNotifications

/// Manages local notification scheduling for check-in reminders.
///
/// Notification types:
/// - **Daily reminder** -- configurable hour/minute, fires if user hasn't checked in
///
/// NOTE: the weekly-review nudge was retired with the weekly-review feature. Its identifier is
/// retained only so `cancelAll()` clears any weekly notification left over from older builds.
final class NotificationService {

    // MARK: - Notification Identifiers

    private enum Identifier {
        static let dailyReminder = "com.agileself.daily-reminder"
        /// Retired (weekly review cut). Kept so `cancelAll()` can remove stale scheduled ones.
        static let weeklyReview = "com.agileself.weekly-review"
    }

    // MARK: - Authorization

    /// Requests notification authorization from the user.
    /// Returns true if authorization was granted.
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Daily Reminder

    /// Schedules a daily check-in reminder at the specified time.
    /// Replaces any existing daily reminder.
    ///
    /// - Parameters:
    ///   - hour: Hour component (0-23). Default: 21 (9 PM).
    ///   - minute: Minute component (0-59). Default: 0.
    func scheduleDailyReminder(hour: Int = 21, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()

        // Remove existing daily reminder
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyReminder])

        let content = UNMutableNotificationContent()
        content.title = "Time for Your Check-in"
        content.body = "Ready for your 15-second check-in? How are you doing today?"
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.dailyReminder,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Cancel All

    /// Removes all pending and delivered notifications managed by this service.
    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Identifier.dailyReminder,
            Identifier.weeklyReview,
        ])
        center.removeDeliveredNotifications(withIdentifiers: [
            Identifier.dailyReminder,
            Identifier.weeklyReview,
        ])
    }
}
