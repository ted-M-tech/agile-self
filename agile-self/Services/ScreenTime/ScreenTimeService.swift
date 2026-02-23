//
//  ScreenTimeService.swift
//  agile-self
//
//  Bridges Screen Time data from the DeviceActivityReport extension into the main app.
//  Uses App Group shared UserDefaults for cross-process communication.
//  FamilyControls authorization is gated behind canImport so the app
//  builds and runs even on Personal Team (free) accounts.
//

import Foundation
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Reads screen time data written by the ScreenTimeReport extension via shared App Group UserDefaults.
@Observable
final class ScreenTimeService {

    // MARK: - Properties

    /// Whether FamilyControls authorization has been granted.
    var isAuthorized = false

    /// Today's screen time in minutes, read from the shared App Group defaults.
    var todayScreenTimeMinutes: Int?

    private let sharedDefaults: UserDefaults?
    private static let appGroupID = "group.tetsuya.agile-self"
    private static let screenTimeMinutesKey = "screenTimeMinutes"
    private static let screenTimeDateKey = "screenTimeDate"

    // MARK: - Init

    init() {
        self.sharedDefaults = UserDefaults(suiteName: Self.appGroupID)
    }

    // MARK: - Authorization

    /// Requests FamilyControls authorization for reading screen time data.
    /// No-op when FamilyControls is unavailable (Personal Team).
    func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
        #endif
    }

    // MARK: - Data Access

    /// Reads the latest screen time value from shared UserDefaults.
    /// Returns the value only if it was written today.
    func fetchTodayScreenTime() -> Int? {
        guard let defaults = sharedDefaults else { return nil }

        let minutes = defaults.integer(forKey: Self.screenTimeMinutesKey)
        guard minutes > 0 else { return nil }

        // Verify the data is from today
        guard let dateString = defaults.string(forKey: Self.screenTimeDateKey),
              let storedDate = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }

        let calendar = Calendar.current
        guard calendar.isDateInToday(storedDate) else { return nil }

        todayScreenTimeMinutes = minutes
        return minutes
    }
}
