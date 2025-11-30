//
//  HealthSummary.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftData

@Model
final class HealthSummary {
    @Attribute(.unique) var id: UUID
    var periodStart: Date
    var periodEnd: Date

    // Sleep metrics
    var avgSleepMinutes: Int?
    var avgSleepQualityScore: Int?  // 0-100

    // Activity metrics
    var avgSteps: Int?
    var totalExerciseMinutes: Int?
    var avgStandHours: Int?
    var avgActiveCalories: Int?

    // Workout metrics
    var totalWorkouts: Int?

    // Computed wellness score
    var wellnessScore: Int?  // 0-100

    var createdAt: Date

    init(
        id: UUID = UUID(),
        periodStart: Date,
        periodEnd: Date,
        avgSleepMinutes: Int? = nil,
        avgSleepQualityScore: Int? = nil,
        avgSteps: Int? = nil,
        totalExerciseMinutes: Int? = nil,
        avgStandHours: Int? = nil,
        avgActiveCalories: Int? = nil,
        totalWorkouts: Int? = nil,
        wellnessScore: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.avgSleepMinutes = avgSleepMinutes
        self.avgSleepQualityScore = avgSleepQualityScore
        self.avgSteps = avgSteps
        self.totalExerciseMinutes = totalExerciseMinutes
        self.avgStandHours = avgStandHours
        self.avgActiveCalories = avgActiveCalories
        self.totalWorkouts = totalWorkouts
        self.wellnessScore = wellnessScore
        self.createdAt = createdAt
    }

    var formattedSleepDuration: String? {
        guard let minutes = avgSleepMinutes else { return nil }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    var formattedSteps: String? {
        guard let steps = avgSteps else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps))
    }
}
