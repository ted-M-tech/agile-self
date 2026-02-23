//
//  HealthSnapshot.swift
//  agile-self
//
//  Created by Claude on 2026/02/22.
//

import Foundation
import SwiftData

/// A daily snapshot of health metrics sourced from HealthKit and Screen Time.
/// All values are daily aggregates -- raw samples are never stored.
@Model
final class HealthSnapshot {

    // MARK: - Persisted Properties

    @Attribute(.unique) var id: UUID
    /// The calendar day this snapshot represents.
    var date: Date
    /// Total sleep duration in minutes (from HKCategoryType.sleepAnalysis).
    var sleepMinutes: Int?
    /// Step count for the day.
    var steps: Int?
    /// Active energy burned in kilocalories.
    var activeCalories: Int?
    /// Exercise/workout minutes for the day.
    var exerciseMinutes: Int?
    /// Resting heart rate in beats per minute.
    var restingHeartRate: Int?
    /// Running + walking distance in meters.
    var runningDistanceMeters: Double?
    /// Total screen time in minutes (from DeviceActivity).
    var screenTimeMinutes: Int?
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        sleepMinutes: Int? = nil,
        steps: Int? = nil,
        activeCalories: Int? = nil,
        exerciseMinutes: Int? = nil,
        restingHeartRate: Int? = nil,
        runningDistanceMeters: Double? = nil,
        screenTimeMinutes: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.sleepMinutes = sleepMinutes
        self.steps = steps
        self.activeCalories = activeCalories
        self.exerciseMinutes = exerciseMinutes
        self.restingHeartRate = restingHeartRate
        self.runningDistanceMeters = runningDistanceMeters
        self.screenTimeMinutes = screenTimeMinutes
        self.createdAt = createdAt
    }

    // MARK: - Formatted Computed Properties

    /// Formatted sleep duration (e.g. "7h 23m"). Returns nil when no data.
    var formattedSleep: String? {
        guard let minutes = sleepMinutes else { return nil }
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 && remaining > 0 {
            return "\(hours)h \(remaining)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(remaining)m"
        }
    }

    /// Formatted step count with thousands separator (e.g. "8,421"). Returns nil when no data.
    var formattedSteps: String? {
        guard let steps = steps else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps))
    }

    /// Formatted screen time duration (e.g. "3h 12m"). Returns nil when no data.
    var formattedScreenTime: String? {
        guard let minutes = screenTimeMinutes else { return nil }
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 && remaining > 0 {
            return "\(hours)h \(remaining)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(remaining)m"
        }
    }

    /// Formatted running distance in kilometers (e.g. "5.2km"). Returns nil when no data.
    var formattedRunDistance: String? {
        guard let meters = runningDistanceMeters else { return nil }
        let km = meters / 1000.0
        return String(format: "%.1fkm", km)
    }

    /// Formatted resting heart rate (e.g. "62 bpm"). Returns nil when no data.
    var formattedHeartRate: String? {
        guard let bpm = restingHeartRate else { return nil }
        return "\(bpm) bpm"
    }
}
