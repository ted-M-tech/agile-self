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
/// Routing rules:
/// - **Daily insights** always use `OnDeviceAIService` (instant, no network, free)
/// - **Weekly questions/summary** use `GeminiAIService` if user has opted in (`allowCloudAI`)
/// - **Monthly reports** use `GeminiAIService` if user has opted in (`allowCloudAI`)
/// - Falls back to `OnDeviceAIService` when cloud AI is not permitted
final class AIServiceRouter: AIServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let onDeviceService: OnDeviceAIService
    private let geminiService: GeminiAIService

    /// Whether the user has opted in to cloud AI processing.
    /// Updated from UserProfile.allowCloudAI.
    var allowCloudAI: Bool = false

    // MARK: - Initialization

    init(onDeviceService: OnDeviceAIService, geminiService: GeminiAIService) {
        self.onDeviceService = onDeviceService
        self.geminiService = geminiService
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
        try await onDeviceService.generateDailyInsight(checkIn: checkIn)
    }

    /// Weekly questions use Gemini when allowed, otherwise on-device heuristics.
    nonisolated func generateWeeklyQuestions(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String] {
        try await onDeviceService.generateWeeklyQuestions(checkIns: checkIns, health: health)
    }

    /// Weekly summary uses Gemini when allowed for deeper conversation analysis.
    nonisolated func generateWeeklySummary(
        conversation: [ConversationMessage],
        checkIns: [DailyCheckIn]
    ) async throws -> WeeklySummaryResult {
        try await onDeviceService.generateWeeklySummary(conversation: conversation, checkIns: checkIns)
    }

    /// Monthly report uses Gemini when allowed for comprehensive trend analysis.
    nonisolated func generateMonthlyReport(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> MonthlyReportResult {
        try await onDeviceService.generateMonthlyReport(checkIns: checkIns, health: health)
    }

    /// Patterns are lightweight and run on-device for instant Insights rendering.
    nonisolated func generatePatterns(from checkIns: [DailyCheckIn]) async throws -> [String] {
        try await onDeviceService.generatePatterns(from: checkIns)
    }
}
