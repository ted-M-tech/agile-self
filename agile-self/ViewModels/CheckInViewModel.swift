//
//  CheckInViewModel.swift
//  agile-self
//
//  ViewModel for the Daily Check-in flow, managing scores, timer, and persistence.
//

import Foundation
import SwiftData

/// Manages the state and logic for the Daily Check-in entry screen.
///
/// Handles:
/// - 4-axis score management (energy, focus, stress, growth)
/// - Optional note with 280-character limit
/// - Elapsed time tracking
/// - Save to SwiftData with streak update and AI insight generation
@Observable
final class CheckInViewModel {

    // MARK: - Score Properties

    /// Energy score (1-10).
    var energyScore: Int = 5
    /// Focus score (1-10).
    var focusScore: Int = 5
    /// Stress score (1-10). Lower is better.
    var stressScore: Int = 5
    /// Growth score (1-10).
    var growthScore: Int = 5

    // MARK: - Note Properties

    /// Free-text note (max 280 characters).
    var noteText: String = ""
    /// Whether the note section is expanded.
    var showNote: Bool = false

    // MARK: - Timer

    /// Elapsed seconds since the check-in screen opened.
    var elapsedSeconds: Int = 0

    // MARK: - State

    /// Whether the check-in is currently being saved.
    var isSaving: Bool = false
    /// Whether to show the confirmation overlay.
    var showConfirmation: Bool = false

    // MARK: - Services

    private let aiService: (any AIServiceProtocol)?
    private let streakService: StreakService?

    // MARK: - Initialization

    init(
        aiService: (any AIServiceProtocol)? = nil,
        streakService: StreakService? = nil
    ) {
        self.aiService = aiService
        self.streakService = streakService
    }

    // MARK: - Computed Properties

    /// Current composite score based on the entered values.
    var compositeScore: Double {
        let invertedStress = 11 - stressScore
        return Double(energyScore + focusScore + invertedStress + growthScore) / 4.0
    }

    /// Returns the composite score of the most recent previous check-in (not from today).
    func previousComposite(context: ModelContext) -> Double? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        var descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate { $0.date < startOfToday },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first?.compositeScore
    }

    // MARK: - Score Binding Helper

    /// Returns the score value for a given dimension.
    func score(for dimension: DimensionType) -> Int {
        switch dimension {
        case .energy: return energyScore
        case .focus: return focusScore
        case .stress: return stressScore
        case .growth: return growthScore
        }
    }

    /// Sets the score value for a given dimension.
    func setScore(_ value: Int, for dimension: DimensionType) {
        let clamped = min(max(value, 1), 10)
        switch dimension {
        case .energy: energyScore = clamped
        case .focus: focusScore = clamped
        case .stress: stressScore = clamped
        case .growth: growthScore = clamped
        }
    }

    // MARK: - Save

    /// Saves the check-in to SwiftData, updates the streak, and generates an AI insight.
    func saveCheckIn(context: ModelContext) async {
        isSaving = true

        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = showNote && !trimmedNote.isEmpty ? trimmedNote : nil

        // Upsert: update today's check-in if it exists, otherwise insert. Mirrors
        // WatchConnectivityService.persistCheckIn and DailyCheckInView.saveCheckIn so
        // the view model, the phone view, and the watch never create duplicate rows
        // for the same day (fixes the duplicate check-in bug).
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: #Predicate { $0.date == today })
        let checkIn: DailyCheckIn
        if let existing = try? context.fetch(descriptor).first {
            existing.energyScore = energyScore
            existing.focusScore = focusScore
            existing.stressScore = stressScore
            existing.growthScore = growthScore
            existing.note = note
            checkIn = existing
        } else {
            let newCheckIn = DailyCheckIn(
                date: today,
                energyScore: energyScore,
                focusScore: focusScore,
                stressScore: stressScore,
                growthScore: growthScore,
                note: note
            )
            context.insert(newCheckIn)
            checkIn = newCheckIn
        }

        // Generate AI insight (routed via AIServiceRouter when injected)
        if let aiService {
            do {
                let insight = try await aiService.generateDailyInsight(checkIn: checkIn)
                checkIn.dailyInsight = insight
            } catch {
                // AI insight generation failed -- continue without it
            }
        }

        // Update streak
        if let streakService {
            streakService.recordCheckIn(context: context)
        }

        isSaving = false
        showConfirmation = true
    }
}
