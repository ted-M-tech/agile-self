//
//  AIServiceRouter.swift
//  agile-self
//
//  Routes AI requests between on-device and cloud (Gemini) services
//  based on task type and user preferences.
//

import Foundation
import SwiftData

/// Routes AI requests to the appropriate backend service.
///
/// NOTE (M3): the local backend prefers the on-device Foundation Models LLM when it is
/// available (evaluated once at init), otherwise the `OnDeviceAIService` NaturalLanguage
/// heuristics. The cloud path (`allowCloudAI` / `GeminiAIService`) remains deferred.
final class AIServiceRouter: AIServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let onDeviceService: OnDeviceAIService
    private let geminiService: GeminiAIService
    private let foundationModelsService: FoundationModelsAIService?
    /// Cached once at init: whether the on-device Foundation Models LLM is usable.
    private let useFoundationModels: Bool

    /// Whether the user has opted in to cloud AI processing.
    /// Updated from UserProfile.allowCloudAI.
    var allowCloudAI: Bool = false

    // MARK: - Initialization

    init(
        onDeviceService: OnDeviceAIService,
        geminiService: GeminiAIService,
        foundationModelsService: FoundationModelsAIService? = nil
    ) {
        self.onDeviceService = onDeviceService
        self.geminiService = geminiService
        self.foundationModelsService = foundationModelsService
        self.useFoundationModels = foundationModelsService?.isModelAvailable ?? false
    }

    /// On-device backend: the Foundation Models LLM when available, else NaturalLanguage heuristics.
    private var localService: any AIServiceProtocol {
        (useFoundationModels ? foundationModelsService : nil) ?? onDeviceService
    }

    // MARK: - Cloud AI Preference

    /// Updates the cloud AI preference from the user's profile.
    /// Call this when the app launches or when the user changes the setting.
    func updateCloudAIPreference(from context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(descriptor).first {
            allowCloudAI = profile.allowCloudAI
        }
    }

    // MARK: - AIServiceProtocol

    /// Daily insights always run on-device for instant feedback.
    nonisolated func generateDailyInsight(checkIn: DailyCheckIn) async throws -> String {
        try await localService.generateDailyInsight(checkIn: checkIn)
    }

    /// Weekly questions use Gemini when allowed, otherwise on-device heuristics.
    nonisolated func generateWeeklyQuestions(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String] {
        try await localService.generateWeeklyQuestions(checkIns: checkIns, health: health)
    }

    /// Weekly summary uses Gemini when allowed for deeper conversation analysis.
    nonisolated func generateWeeklySummary(
        conversation: [ConversationMessage],
        checkIns: [DailyCheckIn]
    ) async throws -> WeeklySummaryResult {
        try await localService.generateWeeklySummary(conversation: conversation, checkIns: checkIns)
    }

    /// Monthly report uses Gemini when allowed for comprehensive trend analysis.
    nonisolated func generateMonthlyReport(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> MonthlyReportResult {
        try await localService.generateMonthlyReport(checkIns: checkIns, health: health)
    }

    /// Patterns are lightweight and run on-device for instant Insights rendering.
    nonisolated func generatePatterns(from checkIns: [DailyCheckIn]) async throws -> [String] {
        try await localService.generatePatterns(from: checkIns)
    }

    /// Connections always run on-device: the numbers are deterministic (AnalyticsService) and
    /// the prose stays local (heuristic, or the on-device Foundation Models LLM when available).
    nonisolated func generateConnections(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String] {
        try await localService.generateConnections(checkIns: checkIns, health: health)
    }

    nonisolated func generateTodayConnection(
        checkIn: DailyCheckIn,
        todayHealth: HealthSnapshot?,
        correlations: [Correlation]
    ) async throws -> String? {
        try await localService.generateTodayConnection(
            checkIn: checkIn,
            todayHealth: todayHealth,
            correlations: correlations
        )
    }
}
