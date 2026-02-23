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

    // MARK: - Sleep Score

    /// Duration-based sleep quality score (0-100). Returns nil when no sleep data.
    ///
    /// Scoring curve:
    /// - <4h  → 0-20 (linear ramp)
    /// - 4-5h → 20-40
    /// - 5-6h → 40-60
    /// - 6-7h → 60-80
    /// - 7-9h → 80-100 (peak at 8h = 100)
    /// - >9h  → gradual decline (100 down to 60 at 12h)
    var sleepScore: Int? {
        guard let minutes = sleepMinutes else { return nil }
        let hours = Double(minutes) / 60.0

        let score: Double
        switch hours {
        case ..<0:
            score = 0
        case 0..<4:
            score = (hours / 4.0) * 20.0
        case 4..<5:
            score = 20.0 + ((hours - 4.0) / 1.0) * 20.0
        case 5..<6:
            score = 40.0 + ((hours - 5.0) / 1.0) * 20.0
        case 6..<7:
            score = 60.0 + ((hours - 6.0) / 1.0) * 20.0
        case 7..<9:
            // Peak at 8h = 100, 7h = 80, 9h = 100
            let distanceFrom8 = abs(hours - 8.0)
            score = 100.0 - (distanceFrom8 * 20.0)
        default:
            // >9h: gradual decline from 100 to 60 over 3 hours (9h-12h)
            let excess = min(hours - 9.0, 3.0)
            score = 100.0 - (excess / 3.0) * 40.0
        }

        return max(0, min(100, Int(score.rounded())))
    }

    /// Human-readable sleep quality label. Returns nil when no sleep data.
    var sleepQualityLabel: String? {
        guard let score = sleepScore else { return nil }
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Below Average"
        default: return "Poor"
        }
    }
}
