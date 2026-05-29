//
//  DailyCheckIn.swift
//  agile-self
//
//  Created by Claude on 2026/02/22.
//

import Foundation
import SwiftData

/// Daily self-assessment with 4-axis scoring (Energy, Focus, Stress, Growth).
/// Each dimension is scored 1-10. Stress is inverted for composite calculation (lower stress = better).
@Model
final class DailyCheckIn {

    // MARK: - Persisted Properties

    @Attribute(.unique) var id: UUID
    /// The calendar day of the check-in, stripped to midnight.
    var date: Date
    /// Energy score: 1 (depleted) to 10 (fully charged).
    var energyScore: Int
    /// Focus score: 1 (scattered) to 10 (laser-focused).
    var focusScore: Int
    /// Stress score: 1 (calm) to 10 (overwhelmed). Low is good.
    var stressScore: Int
    /// Growth score: 1 (stagnant) to 10 (breakthrough).
    var growthScore: Int
    /// Optional free-text note (max 280 characters).
    var note: String?
    /// AI-generated sentiment from the note text. Range: -1.0 (negative) to 1.0 (positive).
    var sentimentScore: Double?
    /// AI-generated daily insight based on scores and note.
    var dailyInsight: String?
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        energyScore: Int = 5,
        focusScore: Int = 5,
        stressScore: Int = 5,
        growthScore: Int = 5,
        note: String? = nil,
        sentimentScore: Double? = nil,
        dailyInsight: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        // Clamp to the valid 1-10 range so out-of-range values (sync / import /
        // future callers) can't break compositeScore, which assumes 1-10.
        self.energyScore = min(max(energyScore, 1), 10)
        self.focusScore = min(max(focusScore, 1), 10)
        self.stressScore = min(max(stressScore, 1), 10)
        self.growthScore = min(max(growthScore, 1), 10)
        self.note = note
        self.sentimentScore = sentimentScore
        self.dailyInsight = dailyInsight
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// Composite score averaging all four dimensions.
    /// Stress is inverted (11 - stressScore) so that lower stress contributes positively.
    var compositeScore: Double {
        let invertedStress = 11 - stressScore
        return Double(energyScore + focusScore + invertedStress + growthScore) / 4.0
    }

    /// Returns the score for a given dimension type.
    func score(for dimension: DimensionType) -> Int {
        switch dimension {
        case .energy: return energyScore
        case .focus: return focusScore
        case .stress: return stressScore
        case .growth: return growthScore
        }
    }

    /// Sets the score for a given dimension type.
    /// The value is clamped to 1-10.
    func setScore(_ value: Int, for dimension: DimensionType) {
        let clamped = min(max(value, 1), 10)
        switch dimension {
        case .energy: energyScore = clamped
        case .focus: focusScore = clamped
        case .stress: stressScore = clamped
        case .growth: growthScore = clamped
        }
    }
}
