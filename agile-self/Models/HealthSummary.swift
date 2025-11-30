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

    // Inverse relationship to Retrospective
    var retrospective: Retrospective?

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

    // MARK: - Validation

    /// Validates that the health summary has valid data ranges
    var isValid: Bool {
        // Validate sleep quality score is in range
        if let score = avgSleepQualityScore, (score < 0 || score > 100) {
            return false
        }

        // Validate wellness score is in range
        if let score = wellnessScore, (score < 0 || score > 100) {
            return false
        }

        // Validate period dates
        if periodStart > periodEnd {
            return false
        }

        return true
    }

    /// Calculates a wellness score based on available health metrics
    func calculateWellnessScore() -> Int? {
        var scores: [Int] = []
        var weights: [Double] = []

        // Sleep quality contributes to wellness (weight: 35%)
        if let sleepScore = avgSleepQualityScore {
            scores.append(sleepScore)
            weights.append(0.35)
        }

        // Activity score based on steps (10k steps = 100, weight: 25%)
        if let steps = avgSteps {
            let stepScore = min(100, (steps * 100) / 10000)
            scores.append(stepScore)
            weights.append(0.25)
        }

        // Exercise minutes (30 min = 100, weight: 25%)
        if let exerciseMinutes = totalExerciseMinutes {
            let exerciseScore = min(100, (exerciseMinutes * 100) / 30)
            scores.append(exerciseScore)
            weights.append(0.25)
        }

        // Stand hours (12 hours = 100, weight: 15%)
        if let standHours = avgStandHours {
            let standScore = min(100, (standHours * 100) / 12)
            scores.append(standScore)
            weights.append(0.15)
        }

        guard !scores.isEmpty else { return nil }

        // Normalize weights
        let totalWeight = weights.reduce(0, +)
        let normalizedWeights = weights.map { $0 / totalWeight }

        // Calculate weighted average
        var weightedSum = 0.0
        for (index, score) in scores.enumerated() {
            weightedSum += Double(score) * normalizedWeights[index]
        }

        return Int(weightedSum.rounded())
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
