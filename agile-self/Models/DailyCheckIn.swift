//
//  DailyCheckIn.swift
//  agile-self
//
//  Created by Claude on 2026/02/22.
//

import Foundation
import SwiftData

/// Daily self-assessment with 4-axis scoring (Energy, Focus, Calm, Growth).
/// Each dimension is scored 1-5 (1 worst … 5 best), higher = better, and the composite is a
/// plain average. The 5-level scale is surfaced in the UI as a row of face glyphs.
@Model
final class DailyCheckIn {

    // MARK: - Persisted Properties

    @Attribute(.unique) var id: UUID
    /// The calendar day of the check-in, stripped to midnight.
    var date: Date
    /// Energy score: 1 (depleted) to 5 (fully charged).
    var energyScore: Int
    /// Focus score: 1 (scattered) to 5 (laser-focused).
    var focusScore: Int
    /// Stores Calm (1 tense … 5 very calm); higher is better. The on-disk name is kept as
    /// `stressScore` for storage stability (avoids a SwiftData schema migration). Read it
    /// through `calmScore` for clarity.
    var stressScore: Int
    /// Growth score: 1 (stagnant) to 5 (breakthrough).
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
        energyScore: Int = 3,
        focusScore: Int = 3,
        stressScore: Int = 3,
        growthScore: Int = 3,
        note: String? = nil,
        sentimentScore: Double? = nil,
        dailyInsight: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        // Clamp to the valid 1-5 range so out-of-range values (sync / import /
        // future callers) can't break compositeScore, which assumes 1-5.
        self.energyScore = min(max(energyScore, 1), 5)
        self.focusScore = min(max(focusScore, 1), 5)
        self.stressScore = min(max(stressScore, 1), 5)
        self.growthScore = min(max(growthScore, 1), 5)
        self.note = note
        self.sentimentScore = sentimentScore
        self.dailyInsight = dailyInsight
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// Read alias for the Calm axis. The value is stored under `stressScore` for storage
    /// stability; semantically it is Calm (1 tense … 5 very calm, higher = better).
    var calmScore: Int { stressScore }

    /// Composite score: a plain average of all four dimensions (each 1-5, higher = better).
    /// A neutral 3/3/3/3 check-in scores exactly 3.0; range is 1.0–5.0.
    var compositeScore: Double {
        Double(energyScore + focusScore + stressScore + growthScore) / 4.0
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
    /// The value is clamped to 1-5.
    func setScore(_ value: Int, for dimension: DimensionType) {
        let clamped = min(max(value, 1), 5)
        switch dimension {
        case .energy: energyScore = clamped
        case .focus: focusScore = clamped
        case .stress: stressScore = clamped
        case .growth: growthScore = clamped
        }
    }
}
