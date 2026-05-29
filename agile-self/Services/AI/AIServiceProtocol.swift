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
}
