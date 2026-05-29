//
//  AIServiceProtocol.swift
//  agile-self
//
//  Unified AI service interface for on-device and cloud AI implementations.
//

import Foundation

// MARK: - AI Result Types

/// Result from generating a weekly summary after AI conversation.
struct WeeklySummaryResult: Sendable {
    let wins: [String]
    let challenges: [String]
    let summary: String
    let aiTakeaway: String
    let suggestedActions: [String]
}

/// Result from generating a monthly report.
struct MonthlyReportResult: Sendable {
    let executiveSummary: String
    let topInsight: String
    let overallScore: Double
    let correlations: [Correlation]
}

// MARK: - AI Service Protocol

/// Unified interface for AI services, allowing seamless switching between
/// on-device (NaturalLanguage + Foundation Models) and cloud (Gemini) implementations.
///
/// Conforming types:
/// - `OnDeviceAIService` -- runs locally using NaturalLanguage framework
/// - `GeminiAIService` -- uses Gemini 2.0 Flash API for deeper analysis
/// - `AIServiceRouter` -- routes requests to the appropriate backend
protocol AIServiceProtocol: Sendable {

    /// Generates a short daily insight based on the check-in scores and optional note.
    /// Typically runs on-device for instant feedback.
    func generateDailyInsight(checkIn: DailyCheckIn) async throws -> String

    /// Generates conversation-starter questions for the weekly review.
    /// Uses the week's check-in data and health snapshots to formulate targeted questions.
    func generateWeeklyQuestions(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String]

    /// Generates a structured weekly summary from the AI conversation and check-in data.
    func generateWeeklySummary(
        conversation: [ConversationMessage],
        checkIns: [DailyCheckIn]
    ) async throws -> WeeklySummaryResult

    /// Generates a comprehensive monthly report with trends, correlations, and insights.
    func generateMonthlyReport(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> MonthlyReportResult

    /// Generates short pattern observations from a set of check-ins.
    /// Typically runs on-device; returns human-readable insight strings.
    func generatePatterns(from checkIns: [DailyCheckIn]) async throws -> [String]

    /// Narrates up to 3 plain-language "connection" statements linking the user's health
    /// metrics to how they feel, derived from the deterministic AnalyticsService correlations
    /// (computed internally). The magnitudes/numbers come from the correlation data — never
    /// invented by the LLM, which may only smooth the prose.
    ///
    /// Returns `[]` when there isn't enough matched data yet (the UI shows an honest waiting
    /// state). All copy uses correlational language ("tends to", "lines up with") — never causal.
    func generateConnections(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String]

    /// Narrates ONE sentence connecting today's standout health metric to today's mood,
    /// informed by the user's historical `correlations` when available.
    ///
    /// - When a relevant correlation exists, it frames the standout metric against the mood
    ///   it tends to track ("You slept 7h23m — and you tend to feel more focused after good sleep…").
    /// - When there's today health data but no established correlation, it returns a neutral,
    ///   PARALLEL observation ("Today you slept 7h23m and logged 8,421 steps alongside a Steady day.").
    /// - When there's no health data at all, returns `nil` (the UI hides the card).
    func generateTodayConnection(
        checkIn: DailyCheckIn,
        todayHealth: HealthSnapshot?,
        correlations: [Correlation]
    ) async throws -> String?
}
