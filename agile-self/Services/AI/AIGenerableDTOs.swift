//
//  AIGenerableDTOs.swift
//  agile-self
//
//  @Generable structures for Foundation Models guided generation, plus bridges to the
//  plain result types in AIServiceProtocol. Entirely gated on the FoundationModels SDK
//  so the project compiles unchanged when the framework is unavailable.
//
//  IMPORTANT: every @Generable type is declared at FILE SCOPE (never nested) because the
//  macro attaches an extension, and Swift forbids extensions on locally-scoped types.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
@Generable(description: "A concise daily self-reflection insight")
struct GenerableDailyInsight {
    @Guide(description: "One or two short, encouraging sentences. No markdown, no preamble.")
    var insight: String
}

@available(iOS 26, *)
@Generable(description: "Open-ended coaching questions for a weekly review")
struct GenerableWeeklyQuestions {
    @Guide(description: "Open-ended weekly-review coaching questions, one per element, no numbering.")
    var questions: [String]
}

@available(iOS 26, *)
@Generable(description: "A structured weekly self-reflection summary")
struct GenerableWeeklySummary {
    @Guide(description: "Concrete wins from the week, short phrases.")
    var wins: [String]
    @Guide(description: "Challenges or struggles from the week, short phrases.")
    var challenges: [String]
    @Guide(description: "A 2-3 sentence narrative summary of the week.")
    var summary: String
    @Guide(description: "One actionable coaching takeaway sentence for next week.")
    var aiTakeaway: String
    @Guide(description: "Specific, concrete actions to try next week.")
    var suggestedActions: [String]

    /// Counts are clamped here (not via @Guide) to keep the first build's API surface minimal.
    func toResult() -> WeeklySummaryResult {
        WeeklySummaryResult(
            wins: Array(wins.prefix(4)),
            challenges: Array(challenges.prefix(4)),
            summary: summary,
            aiTakeaway: aiTakeaway,
            suggestedActions: Array(suggestedActions.prefix(3))
        )
    }
}

@available(iOS 26, *)
@Generable(description: "The narrative portion of a monthly self-reflection report")
struct GenerableMonthlyReport {
    @Guide(description: "A 3-4 sentence executive summary of the month's trend. Do not state any numbers you were not given.")
    var executiveSummary: String
    @Guide(description: "The single most impactful insight for the month, one sentence.")
    var topInsight: String

    /// The numeric score and correlations are computed deterministically and passed in —
    /// the model never emits a number.
    func toResult(overallScore: Double, correlations: [Correlation]) -> MonthlyReportResult {
        MonthlyReportResult(
            executiveSummary: executiveSummary,
            topInsight: topInsight,
            overallScore: overallScore,
            correlations: correlations
        )
    }
}

@available(iOS 26, *)
@Generable(description: "Behavioral pattern observations from a series of check-ins")
struct GenerablePatterns {
    @Guide(description: "Human-readable behavioral pattern observations, one per element.")
    var patterns: [String]
}

#endif
