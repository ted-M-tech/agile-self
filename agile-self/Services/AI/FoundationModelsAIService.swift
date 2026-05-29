//
//  FoundationModelsAIService.swift
//  agile-self
//
//  AIServiceProtocol backed by Apple's on-device Foundation Models LLM (iOS 26+), with a
//  guaranteed fallback to the heuristic OnDeviceAIService. Three layered guarantees keep
//  the app working everywhere:
//    1. Compile-time: every Foundation Models symbol is inside `#if canImport(FoundationModels)`.
//    2. Availability: model availability is read ONCE in init; unavailable → always fall back.
//    3. Runtime: every generation is wrapped in do/catch and degrades to heuristics on any throw
//       or empty output.
//  The LLM produces PROSE only — numeric scores (avgComposite) and correlations
//  (AnalyticsService) are computed deterministically and never hallucinated.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

final class FoundationModelsAIService: AIServiceProtocol, @unchecked Sendable {

    private let fallback: OnDeviceAIService

    /// Whether the on-device model is usable. Cached once; false on simulator / ineligible
    /// devices / Apple Intelligence off.
    let isModelAvailable: Bool

    init(fallback: OnDeviceAIService = OnDeviceAIService()) {
        self.fallback = fallback
        #if canImport(FoundationModels)
        if #available(iOS 26, *), case .available = SystemLanguageModel.default.availability {
            self.isModelAvailable = true
        } else {
            self.isModelAvailable = false
        }
        #else
        self.isModelAvailable = false
        #endif
    }

    // MARK: - Plain-text generation helper

    /// Runs a single-shot text generation in a fresh session. Returns nil on unavailable,
    /// throw, or empty output (caller then falls back to heuristics).
    private nonisolated func generateText(instructions: String, prompt: String) async -> String? {
        guard isModelAvailable else { return nil }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    // MARK: - AIServiceProtocol

    nonisolated func generateDailyInsight(checkIn: DailyCheckIn) async throws -> String {
        let instructions = "You are a concise, supportive self-growth coach. Reply with at most 2 short sentences, warm and specific. No lists, no markdown, no emojis."
        let prompt = "Energy=\(checkIn.energyScore) Focus=\(checkIn.focusScore) Stress=\(checkIn.stressScore) Growth=\(checkIn.growthScore) Composite=\(String(format: "%.1f", checkIn.compositeScore)). Note: \(checkIn.note ?? "(none)")"
        if let text = await generateText(instructions: instructions, prompt: prompt) {
            return text
        }
        return try await fallback.generateDailyInsight(checkIn: checkIn)
    }

    nonisolated func generateWeeklyQuestions(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String] {
        guard isModelAvailable else {
            return try await fallback.generateWeeklyQuestions(checkIns: checkIns, health: health)
        }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession(instructions: "You are a thoughtful weekly-review coach. Produce open-ended questions that help the user reflect on the past week.")
                let response = try await session.respond(
                    to: Self.weeklyQuestionsPrompt(checkIns: checkIns, health: health),
                    generating: GenerableWeeklyQuestions.self
                )
                let questions = response.content.questions
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !questions.isEmpty { return Array(questions.prefix(6)) }
            } catch {
                // fall through to heuristic
            }
        }
        #endif
        return try await fallback.generateWeeklyQuestions(checkIns: checkIns, health: health)
    }

    nonisolated func generateWeeklySummary(
        conversation: [ConversationMessage],
        checkIns: [DailyCheckIn]
    ) async throws -> WeeklySummaryResult {
        guard isModelAvailable else {
            return try await fallback.generateWeeklySummary(conversation: conversation, checkIns: checkIns)
        }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession(instructions: "You are a self-growth coach summarizing a user's week from their check-in numbers and reflection notes. Be concrete and encouraging; never invent statistics.")
                let response = try await session.respond(
                    to: Self.weeklySummaryPrompt(conversation: conversation, checkIns: checkIns),
                    generating: GenerableWeeklySummary.self
                )
                return response.content.toResult()
            } catch {
                // fall through to heuristic
            }
        }
        #endif
        return try await fallback.generateWeeklySummary(conversation: conversation, checkIns: checkIns)
    }

    nonisolated func generateMonthlyReport(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> MonthlyReportResult {
        // Deterministic number + real correlations, identical on every path.
        let correlations = AnalyticsService().detectCorrelations(checkIns: checkIns, health: health)
        let avgComposite = checkIns.isEmpty
            ? 5.0
            : checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)

        guard isModelAvailable else {
            return try await fallback.generateMonthlyReport(checkIns: checkIns, health: health)
        }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession(instructions: "You are a self-growth analyst writing the narrative of a monthly report. Write prose only; never state a number you were not explicitly given.")
                let response = try await session.respond(
                    to: Self.monthlyReportPrompt(checkIns: checkIns, avgComposite: avgComposite, correlations: correlations),
                    generating: GenerableMonthlyReport.self
                )
                return response.content.toResult(overallScore: avgComposite, correlations: correlations)
            } catch {
                // fall through to heuristic
            }
        }
        #endif
        return try await fallback.generateMonthlyReport(checkIns: checkIns, health: health)
    }

    nonisolated func generatePatterns(from checkIns: [DailyCheckIn]) async throws -> [String] {
        // Preserve the heuristic's data-sufficiency contract.
        guard checkIns.count >= 7 else {
            return try await fallback.generatePatterns(from: checkIns)
        }
        guard isModelAvailable else {
            return try await fallback.generatePatterns(from: checkIns)
        }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession(instructions: "You identify behavioral patterns from a series of daily self-check-ins. Output concise, human-readable observations.")
                let response = try await session.respond(
                    to: Self.patternsPrompt(checkIns: checkIns),
                    generating: GenerablePatterns.self
                )
                let patterns = response.content.patterns
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !patterns.isEmpty { return Array(patterns.prefix(3)) }
            } catch {
                // fall through to heuristic
            }
        }
        #endif
        return try await fallback.generatePatterns(from: checkIns)
    }

    // MARK: - Prompt Builders (anonymized aggregates)

    private static func average(_ values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private static func weeklyQuestionsPrompt(checkIns: [DailyCheckIn], health: [HealthSnapshot]) -> String {
        guard !checkIns.isEmpty else {
            return "The user has no check-ins logged this week. Ask 4 gentle, open-ended questions to help them reflect on their week and restart the habit."
        }
        let avgComposite = checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)
        var lines = [
            "Weekly check-in aggregates (1-10 scales; stress is inverted in composite):",
            "Days logged: \(checkIns.count)",
            String(format: "Avg composite: %.1f", avgComposite),
            String(format: "Avg energy: %.1f, focus: %.1f, stress: %.1f, growth: %.1f",
                   average(checkIns.map(\.energyScore)), average(checkIns.map(\.focusScore)),
                   average(checkIns.map(\.stressScore)), average(checkIns.map(\.growthScore))),
        ]
        let sleeps = health.compactMap(\.sleepMinutes)
        if !sleeps.isEmpty {
            lines.append(String(format: "Avg sleep: %.1f h", Double(sleeps.reduce(0, +)) / Double(sleeps.count) / 60.0))
        }
        lines.append("Generate up to 6 open-ended coaching questions tailored to these aggregates, plus one forward-looking question about next week.")
        return lines.joined(separator: "\n")
    }

    private static func weeklySummaryPrompt(conversation: [ConversationMessage], checkIns: [DailyCheckIn]) -> String {
        let avgComposite = checkIns.isEmpty ? 5.0 : checkIns.map(\.compositeScore).reduce(0, +) / Double(checkIns.count)
        let best = checkIns.max(by: { $0.compositeScore < $1.compositeScore })?.compositeScore
        let worst = checkIns.min(by: { $0.compositeScore < $1.compositeScore })?.compositeScore
        var lines = [
            "Summarize the user's week from these aggregates and their own reflection replies.",
            "Days logged: \(checkIns.count)",
            String(format: "Avg composite: %.1f", avgComposite),
        ]
        if let best { lines.append(String(format: "Best day composite: %.1f", best)) }
        if let worst { lines.append(String(format: "Lowest day composite: %.1f", worst)) }
        let replies = conversation.filter { $0.role == .user }.map(\.content)
        if !replies.isEmpty {
            lines.append("User reflection replies:")
            for (i, r) in replies.prefix(8).enumerated() {
                lines.append("Reply \(i + 1): \(r)")
            }
        }
        lines.append("Produce concrete wins, challenges, a short narrative summary, one actionable takeaway, and specific suggested actions for next week. Do not invent numbers beyond those given.")
        return lines.joined(separator: "\n")
    }

    private static func monthlyReportPrompt(checkIns: [DailyCheckIn], avgComposite: Double, correlations: [Correlation]) -> String {
        let midpoint = checkIns.count / 2
        let firstHalf = Array(checkIns.prefix(midpoint))
        let secondHalf = Array(checkIns.suffix(from: midpoint))
        let firstAvg = firstHalf.isEmpty ? avgComposite : firstHalf.map(\.compositeScore).reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.isEmpty ? avgComposite : secondHalf.map(\.compositeScore).reduce(0, +) / Double(secondHalf.count)
        var lines = [
            "Write the narrative for a monthly self-growth report. Use ONLY the facts below; do not state any other numbers.",
            "Check-ins logged: \(checkIns.count)",
            String(format: "Average composite score: %.1f", avgComposite),
            String(format: "First-half avg: %.1f, second-half avg: %.1f (trend %@%.1f)",
                   firstAvg, secondAvg, secondAvg - firstAvg >= 0 ? "+" : "-", abs(secondAvg - firstAvg)),
        ]
        if !correlations.isEmpty {
            lines.append("Detected correlations (already computed — reference qualitatively, do not restate coefficients):")
            for c in correlations.prefix(5) {
                lines.append("- \(c.description)")
            }
        }
        lines.append("Write a 3-4 sentence executive summary and one single most-impactful insight sentence.")
        return lines.joined(separator: "\n")
    }

    private static func patternsPrompt(checkIns: [DailyCheckIn]) -> String {
        let lines = [
            "Identify up to 3 behavioral patterns from \(checkIns.count) daily check-ins (1-10 scales).",
            String(format: "Avg energy: %.1f, focus: %.1f, stress: %.1f, growth: %.1f",
                   average(checkIns.map(\.energyScore)), average(checkIns.map(\.focusScore)),
                   average(checkIns.map(\.stressScore)), average(checkIns.map(\.growthScore))),
            "Each pattern: one concise, human-readable observation.",
        ]
        return lines.joined(separator: "\n")
    }
}
