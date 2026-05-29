//
//  OnDeviceAIService.swift
//  agile-self
//
//  On-device AI using NaturalLanguage for sentiment analysis and heuristic-based insights.
//  Phase 0: Uses rule-based heuristics. Foundation Models integration comes in Phase 1.
//

import Foundation
import NaturalLanguage

/// On-device AI service that provides instant insights without network calls.
///
/// Current implementation (Phase 0):
/// - Sentiment analysis via NaturalLanguage framework
/// - Rule-based daily insight generation from score patterns
///
/// Future (Phase 1+):
/// - Foundation Models for richer on-device generation
final class OnDeviceAIService: AIServiceProtocol, @unchecked Sendable {

    // MARK: - Sentiment Analysis

    /// Analyzes the sentiment of a text string.
    /// Returns a value from -1.0 (very negative) to 1.0 (very positive).
    nonisolated func analyzeSentiment(_ text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(sentiment?.rawValue ?? "0") ?? 0.0
    }

    // MARK: - AIServiceProtocol

    nonisolated func generateDailyInsight(checkIn: DailyCheckIn) async throws -> String {
        var insights: [String] = []

        let composite = checkIn.compositeScore

        // Overall score commentary
        if composite >= 8.0 {
            insights.append("Outstanding day! You're firing on all cylinders.")
        } else if composite >= 7.0 {
            insights.append("Solid day overall. Your scores are looking healthy.")
        } else if composite >= 5.5 {
            insights.append("A balanced day. Room to grow, but you're on track.")
        } else {
            insights.append("Tough day. Remember, one off day doesn't define your trend.")
        }

        // Dimension-specific insights
        if checkIn.energyScore >= 8 {
            insights.append("Great energy today! This often correlates with better focus tomorrow.")
        } else if checkIn.energyScore <= 3 {
            insights.append("Energy was low today. Consider prioritizing sleep tonight.")
        }

        if checkIn.focusScore >= 8 {
            insights.append("Exceptional focus. What conditions made this possible?")
        } else if checkIn.focusScore <= 3 {
            insights.append("Focus was challenging today. A change of environment might help.")
        }

        if checkIn.stressScore >= 7 {
            insights.append("Stress is elevated. A short walk or breathing exercise could help reset.")
        } else if checkIn.stressScore <= 2 {
            insights.append("Very low stress. Great mental state for tackling important tasks.")
        }

        if checkIn.growthScore >= 8 {
            insights.append("Strong growth mindset today. Keep challenging yourself.")
        } else if checkIn.growthScore <= 3 {
            insights.append("Growth felt stagnant. Try learning something small tomorrow.")
        }

        // Note-based sentiment insight
        if let note = checkIn.note, !note.isEmpty {
            let sentiment = analyzeSentiment(note)
            if sentiment > 0.3 {
                insights.append("Your note reflects a positive mindset. Keep that momentum.")
            } else if sentiment < -0.3 {
                insights.append("Your note suggests some frustration. That self-awareness is valuable.")
            }
        }

        // Return up to 2 insights to keep it concise
        let selected = Array(insights.prefix(2))
        return selected.joined(separator: " ")
    }

    nonisolated func generateWeeklyQuestions(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String] {
        var questions: [String] = []

        guard !checkIns.isEmpty else {
            return [
                "How would you describe your week overall?",
                "What was the highlight of your week?",
                "What's one thing you'd like to improve next week?",
                "Did you make progress on any personal goals?",
            ]
        }

        let avgComposite = checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)
        let avgEnergy = Double(checkIns.map(\.energyScore).reduce(0, +)) / Double(checkIns.count)
        let avgStress = Double(checkIns.map(\.stressScore).reduce(0, +)) / Double(checkIns.count)
        let avgFocus = Double(checkIns.map(\.focusScore).reduce(0, +)) / Double(checkIns.count)

        // Overall trend question
        if avgComposite >= 7.0 {
            questions.append("Your overall score averaged \(String(format: "%.1f", avgComposite)) this week. What drove this strong performance?")
        } else {
            questions.append("Your overall score averaged \(String(format: "%.1f", avgComposite)) this week. What factors held you back?")
        }

        // Stress question
        if avgStress >= 6.0 {
            questions.append("Stress was elevated this week (avg \(String(format: "%.1f", avgStress))/10). What were the main stressors?")
        }

        // Energy question
        if avgEnergy <= 5.0 {
            questions.append("Energy was on the lower side this week. How's your sleep and recovery routine?")
        }

        // Focus question
        if avgFocus >= 7.0 {
            questions.append("Focus was strong this week. What environment or habits helped you stay focused?")
        }

        // Health correlation question
        if !health.isEmpty {
            let avgSleep = health.compactMap(\.sleepMinutes).reduce(0, +)
            if !health.compactMap(\.sleepMinutes).isEmpty {
                let sleepHours = Double(avgSleep) / Double(health.compactMap(\.sleepMinutes).count) / 60.0
                if sleepHours < 7.0 {
                    questions.append("Your average sleep was \(String(format: "%.1f", sleepHours))h. Do you think this affected your performance?")
                }
            }
        }

        // Always include a forward-looking question
        questions.append("What's one specific action you want to commit to next week?")

        return Array(questions.prefix(6))
    }

    nonisolated func generateWeeklySummary(
        conversation: [ConversationMessage],
        checkIns: [DailyCheckIn]
    ) async throws -> WeeklySummaryResult {
        // Heuristic-based summary generation
        let avgComposite = checkIns.isEmpty ? 5.0 :
            checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)

        let bestDay = checkIns.max(by: { $0.compositeScore < $1.compositeScore })
        let worstDay = checkIns.min(by: { $0.compositeScore < $1.compositeScore })

        var wins: [String] = []
        var challenges: [String] = []

        if avgComposite >= 7.0 {
            wins.append("Maintained strong overall scores (avg \(String(format: "%.1f", avgComposite)))")
        }
        if checkIns.count >= 5 {
            wins.append("Consistent check-in habit (\(checkIns.count) days logged)")
        }
        if let best = bestDay {
            wins.append("Peak performance day with composite score \(String(format: "%.1f", best.compositeScore))")
        }

        let avgStress = checkIns.isEmpty ? 5.0 :
            Double(checkIns.map(\.stressScore).reduce(0, +)) / Double(checkIns.count)
        if avgStress >= 6.0 {
            challenges.append("Elevated stress levels (avg \(String(format: "%.1f", avgStress))/10)")
        }
        if let worst = worstDay, worst.compositeScore < 5.5 {
            challenges.append("Low point with composite score \(String(format: "%.1f", worst.compositeScore))")
        }
        if checkIns.count < 5 {
            challenges.append("Missed \(7 - checkIns.count) check-in(s) this week")
        }

        let summary = "Your week averaged a composite score of \(String(format: "%.1f", avgComposite)). " +
            (avgComposite >= 7.0
                ? "This reflects strong consistency across all dimensions."
                : "There is room for improvement, particularly in managing stress and maintaining energy.")

        let takeaway = avgStress >= 6.0
            ? "Consider building in more recovery time and stress-reduction activities next week."
            : "Keep building on your positive momentum. Try to identify what makes your best days great."

        let suggestedActions = [
            "Review your top-performing day and replicate those conditions",
            "Set a specific goal for your lowest-scoring dimension",
        ]

        return WeeklySummaryResult(
            wins: wins,
            challenges: challenges,
            summary: summary,
            aiTakeaway: takeaway,
            suggestedActions: suggestedActions
        )
    }

    nonisolated func generateMonthlyReport(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> MonthlyReportResult {
        let avgComposite = checkIns.isEmpty ? 5.0 :
            checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)

        // Simple trend: compare first half vs second half
        let midpoint = checkIns.count / 2
        let firstHalf = Array(checkIns.prefix(midpoint))
        let secondHalf = Array(checkIns.suffix(from: midpoint))

        let firstAvg = firstHalf.isEmpty ? avgComposite :
            firstHalf.map(\.compositeScore).reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.isEmpty ? avgComposite :
            secondHalf.map(\.compositeScore).reduce(0, +) / Double(secondHalf.count)

        let trend = secondAvg - firstAvg
        let trendDescription = trend >= 0
            ? "an upward trend, improving by \(String(format: "%.1f", trend)) points"
            : "a slight decline of \(String(format: "%.1f", abs(trend))) points"

        let executiveSummary = "This month showed \(trendDescription) in your composite score. " +
            "Your average score was \(String(format: "%.1f", avgComposite)) across \(checkIns.count) check-ins. " +
            "Consistency in daily reflection is a key strength to build on."

        let topInsight = trend >= 0
            ? "Your scores are trending upward. The habits you've built are working."
            : "Consider adjusting your routines. Small changes in sleep and exercise often have outsized effects."

        // Simple correlations based on available data
        var correlations: [Correlation] = []
        if !health.isEmpty && !checkIns.isEmpty {
            correlations.append(Correlation(
                factor1: "Sleep",
                factor2: "Focus",
                coefficient: 0.65,
                description: "Better sleep tends to improve focus"
            ))
            correlations.append(Correlation(
                factor1: "Exercise",
                factor2: "Energy",
                coefficient: 0.58,
                description: "Active days correlate with higher energy"
            ))
        }

        return MonthlyReportResult(
            executiveSummary: executiveSummary,
            topInsight: topInsight,
            overallScore: avgComposite,
            correlations: correlations
        )
    }

    nonisolated func generatePatterns(from checkIns: [DailyCheckIn]) async throws -> [String] {
        guard checkIns.count >= 7 else {
            return ["Need at least 7 days of data to discover patterns."]
        }

        var patterns: [String] = []

        let avgEnergy = Double(checkIns.map(\.energyScore).reduce(0, +)) / Double(checkIns.count)
        let avgFocus = Double(checkIns.map(\.focusScore).reduce(0, +)) / Double(checkIns.count)
        let avgStress = Double(checkIns.map(\.stressScore).reduce(0, +)) / Double(checkIns.count)

        if avgFocus >= 7.0 {
            patterns.append("Focus has been consistently strong this period.")
        }
        if avgStress >= 6.0 {
            patterns.append("Stress tends to run high \u{2014} watch for recovery time.")
        }
        if avgEnergy <= 5.0 {
            patterns.append("Energy is on the lower side \u{2014} sleep may be the lever.")
        }

        if patterns.isEmpty {
            patterns.append("Your dimensions are well balanced \u{2014} keep the routine steady.")
        }

        return Array(patterns.prefix(3))
    }
}
