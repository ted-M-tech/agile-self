//
//  AIService.swift
//  agile-self
//
//  Service for AI-powered insights (on-device + optional cloud).
//

import Foundation

/// Provides AI-generated insights for check-ins and reviews.
/// Currently returns placeholder insights; will integrate
/// NaturalLanguage (on-device) and Gemini API (cloud) in a future phase.
@Observable
final class AIService {

    // MARK: - State

    var isProcessing = false

    // MARK: - Daily Insight

    /// Generates a brief AI insight based on a daily check-in's scores.
    /// Returns nil if generation fails.
    func generateDailyInsight(checkIn: DailyCheckIn) async -> String? {
        isProcessing = true
        defer { isProcessing = false }

        // Simulate a brief processing delay
        try? await Task.sleep(for: .milliseconds(500))

        // Placeholder logic: generate a contextual insight based on scores
        let composite = checkIn.compositeScore

        if composite >= 8.0 {
            return "Outstanding day! Your scores are well above average. Keep up whatever you did today."
        } else if composite >= 6.5 {
            return "Solid day overall. Your balance across dimensions is healthy."
        } else if checkIn.stressScore >= 7 {
            return "Your stress is elevated today. Consider a brief reset activity before bed."
        } else if checkIn.energyScore <= 3 {
            return "Low energy detected. Check your sleep quality and consider an earlier bedtime tonight."
        } else if checkIn.focusScore <= 3 {
            return "Focus was challenging today. Try breaking tomorrow's tasks into smaller blocks."
        } else {
            return "Every day is data. Small improvements compound over time."
        }
    }

    // MARK: - Weekly Patterns (placeholder)

    /// Generates pattern observations from a set of check-ins.
    /// Returns placeholder patterns for now.
    func generatePatterns(from checkIns: [DailyCheckIn]) async -> [String] {
        isProcessing = true
        defer { isProcessing = false }

        try? await Task.sleep(for: .milliseconds(300))

        guard checkIns.count >= 7 else {
            return ["Need at least 7 days of data to discover patterns."]
        }

        return [
            "Focus peaks on run days",
            "Sleep affects stress",
            "Midweek energy dip"
        ]
    }
}
