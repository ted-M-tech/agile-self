//
//  GeminiAIService.swift
//  agile-self
//
//  Cloud AI service using Gemini 2.0 Flash API.
//  Phase 0: Returns structured placeholder data.
//  Phase 2: Full Gemini API integration with data anonymization.
//

import Foundation

/// Cloud-based AI service backed by Google Gemini 2.0 Flash API.
///
/// Privacy:
/// - All data is anonymized before sending to the API.
/// - User names are never included in requests.
/// - Dates are offset-encoded (Day 1, Day 2, ...).
/// - Only text notes and numerical scores are transmitted.
///
/// Current status: Placeholder implementation returning structured mock responses.
/// The API integration structure is in place for Phase 2 implementation.
final class GeminiAIService: AIServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// The Gemini API endpoint (to be configured via environment or Keychain).
    private nonisolated let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private nonisolated let model = "gemini-2.0-flash"

    // MARK: - Data Anonymization

    /// Anonymizes check-in data before sending to the cloud API.
    /// - Removes user identity information
    /// - Offsets dates to Day 1, Day 2, etc.
    /// - Retains only numerical scores and text notes
    nonisolated private func anonymize(checkIns: [DailyCheckIn]) -> [[String: Any]] {
        let sorted = checkIns.sorted { $0.date < $1.date }
        return sorted.enumerated().map { index, checkIn in
            var entry: [String: Any] = [
                "day": index + 1,
                "energy": checkIn.energyScore,
                "focus": checkIn.focusScore,
                "stress": checkIn.stressScore,
                "growth": checkIn.growthScore,
                "composite": checkIn.compositeScore,
            ]
            if let note = checkIn.note {
                entry["note"] = note
            }
            return entry
        }
    }

    /// Anonymizes health data before sending to the cloud API.
    nonisolated private func anonymize(health: [HealthSnapshot]) -> [[String: Any]] {
        let sorted = health.sorted { $0.date < $1.date }
        return sorted.enumerated().map { index, snapshot in
            var entry: [String: Any] = ["day": index + 1]
            if let sleep = snapshot.sleepMinutes { entry["sleepMinutes"] = sleep }
            if let steps = snapshot.steps { entry["steps"] = steps }
            if let cal = snapshot.activeCalories { entry["activeCalories"] = cal }
            if let ex = snapshot.exerciseMinutes { entry["exerciseMinutes"] = ex }
            if let hr = snapshot.restingHeartRate { entry["restingHeartRate"] = hr }
            if let dist = snapshot.runningDistanceMeters { entry["runningDistanceMeters"] = dist }
            return entry
        }
    }

    // MARK: - AIServiceProtocol

    /// Phase 0: Returns a heuristic insight. Phase 2 will use Gemini for richer generation.
    nonisolated func generateDailyInsight(checkIn: DailyCheckIn) async throws -> String {
        // Daily insights are handled on-device; this is a fallback.
        let composite = checkIn.compositeScore
        if composite >= 7.5 {
            return "Strong day across the board. Your consistency is building momentum."
        } else if composite >= 5.5 {
            return "A balanced day. Look for small wins to build on tomorrow."
        } else {
            return "Everyone has off days. Focus on one small improvement tomorrow."
        }
    }

    nonisolated func generateWeeklyQuestions(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String] {
        // Phase 2: Send anonymized data to Gemini and parse structured questions.
        // For now, return contextual placeholder questions.
        let _ = anonymize(checkIns: checkIns)
        let _ = anonymize(health: health)

        let avgComposite = checkIns.isEmpty ? 5.0 :
            checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)

        return [
            "Your overall score this week was \(String(format: "%.1f", avgComposite)). What contributed most to this?",
            "Which day felt like your peak performance? What made it different?",
            "Were there any moments of unexpected stress this week?",
            "How did your physical health (sleep, exercise) affect your mental state?",
            "What's one habit you want to strengthen next week?",
            "If you could change one thing about this week, what would it be?",
        ]
    }

    nonisolated func generateWeeklySummary(
        conversation: [ConversationMessage],
        checkIns: [DailyCheckIn]
    ) async throws -> WeeklySummaryResult {
        // Phase 2: Send conversation + anonymized data to Gemini for deep analysis.
        let avgComposite = checkIns.isEmpty ? 5.0 :
            checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)

        // Extract themes from conversation (placeholder logic)
        let userMessages = conversation.filter { $0.role == .user }.map(\.content)
        let hasExerciseMention = userMessages.contains { $0.localizedCaseInsensitiveContains("run") || $0.localizedCaseInsensitiveContains("exercise") || $0.localizedCaseInsensitiveContains("workout") }

        var wins = [
            "Maintained a consistent check-in habit",
            "Overall composite score: \(String(format: "%.1f", avgComposite))",
        ]
        if hasExerciseMention {
            wins.append("Recognized the positive impact of physical activity")
        }

        var challenges = [String]()
        let avgStress = checkIns.isEmpty ? 5.0 :
            Double(checkIns.map(\.stressScore).reduce(0, +)) / Double(checkIns.count)
        if avgStress >= 5.0 {
            challenges.append("Stress management needs attention (avg \(String(format: "%.1f", avgStress))/10)")
        }
        if checkIns.count < 7 {
            challenges.append("Missed \(7 - checkIns.count) day(s) of check-ins")
        }

        return WeeklySummaryResult(
            wins: wins,
            challenges: challenges,
            summary: "A productive week with an average composite of \(String(format: "%.1f", avgComposite)). Your self-awareness through daily reflection is a strong foundation for growth.",
            aiTakeaway: "Focus on the conditions that create your best days and try to replicate them consistently.",
            suggestedActions: [
                "Identify and protect your peak focus hours",
                "Build a pre-sleep routine to improve recovery",
            ]
        )
    }

    nonisolated func generateMonthlyReport(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> MonthlyReportResult {
        // Phase 2: Send full month's anonymized data to Gemini for comprehensive analysis.
        let _ = anonymize(checkIns: checkIns)
        let _ = anonymize(health: health)

        let avgComposite = checkIns.isEmpty ? 5.0 :
            checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)

        let correlations = [
            Correlation(
                factor1: "Sleep",
                factor2: "Focus",
                coefficient: 0.72,
                description: "Sleep\u{2191} = Focus\u{2191}"
            ),
            Correlation(
                factor1: "Exercise",
                factor2: "Energy",
                coefficient: 0.68,
                description: "Exercise\u{2191} = Energy\u{2191}"
            ),
            Correlation(
                factor1: "Screen Time",
                factor2: "Stress",
                coefficient: 0.54,
                description: "Screen Time\u{2191} = Stress\u{2191}"
            ),
        ]

        return MonthlyReportResult(
            executiveSummary: "This month demonstrated steady engagement with self-reflection. Your composite score averaged \(String(format: "%.1f", avgComposite)) across \(checkIns.count) check-ins. The data reveals meaningful correlations between your physical health metrics and mental performance.",
            topInsight: "Consistent exercise and sleep above 7 hours correlate with your best-performing days.",
            overallScore: avgComposite,
            correlations: correlations
        )
    }

    nonisolated func generatePatterns(from checkIns: [DailyCheckIn]) async throws -> [String] {
        // Phase 2: derive patterns from anonymized data via Gemini.
        _ = anonymize(checkIns: checkIns)
        guard checkIns.count >= 7 else {
            return ["Need at least 7 days of data to discover patterns."]
        }
        return [
            "Focus peaks on your most active days.",
            "Sleep quality strongly shapes next-day stress.",
            "A midweek energy dip recurs in your data.",
        ]
    }
}
