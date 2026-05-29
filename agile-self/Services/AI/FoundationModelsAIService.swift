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
import os

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
        AppLog.ai.notice("FoundationModels availability=\(self.isModelAvailable ? "available" : "unavailable", privacy: .public) (sim/ineligible/AI-off → unavailable → heuristic fallback)")
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
        let prompt = "Energy=\(checkIn.energyScore) Focus=\(checkIn.focusScore) Calm=\(checkIn.calmScore) Growth=\(checkIn.growthScore) Composite=\(String(format: "%.1f", checkIn.compositeScore)) (all 1-5, higher is better; Calm 5 = very calm). Note: \(checkIn.note ?? "(none)")"
        if let text = await generateText(instructions: instructions, prompt: prompt) {
            AppLog.ai.notice("dailyInsight backend=foundationModels")
            return text
        }
        AppLog.ai.notice("dailyInsight backend=heuristic")
        return try await fallback.generateDailyInsight(checkIn: checkIn)
    }

    nonisolated func generateMonthlyReport(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> MonthlyReportResult {
        // Deterministic number + real correlations, identical on every path.
        let correlations = AnalyticsService().detectCorrelations(checkIns: checkIns, health: health)
        let avgComposite = checkIns.isEmpty
            ? 3.0
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
                AppLog.ai.notice("monthlyReport backend=foundationModels overallScore=\(avgComposite, privacy: .public) correlations=\(correlations.count, privacy: .public) (numbers deterministic, prose only from LLM)")
                return response.content.toResult(overallScore: avgComposite, correlations: correlations)
            } catch {
                // fall through to heuristic
            }
        }
        #endif
        AppLog.ai.notice("monthlyReport backend=heuristic overallScore=\(avgComposite, privacy: .public) correlations=\(correlations.count, privacy: .public)")
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
                if !patterns.isEmpty {
                    AppLog.ai.notice("patterns backend=foundationModels count=\(patterns.count, privacy: .public)")
                    return Array(patterns.prefix(3))
                }
            } catch {
                // fall through to heuristic
            }
        }
        #endif
        AppLog.ai.notice("patterns backend=heuristic checkIns=\(checkIns.count, privacy: .public)")
        return try await fallback.generatePatterns(from: checkIns)
    }

    // MARK: - Connections (mood ↔ health)

    /// The deterministic connection statements are computed first and used as the source of
    /// truth (they carry the real numbers). The LLM may only soften the prose, one statement at
    /// a time, with a guaranteed fallback to the heuristic sentence on any failure/empty output
    /// or if it tries to introduce a digit not already present.
    nonisolated func generateConnections(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) async throws -> [String] {
        let base = ConnectionNarrator.connections(checkIns: checkIns, health: health)
        guard !base.isEmpty, isModelAvailable else {
            AppLog.ai.notice("connections backend=heuristic count=\(base.count, privacy: .public)")
            return base
        }
        let instructions = "You rephrase one factual sentence about a correlation between a health metric and a mood, keeping it warm, honest, and under 22 words. Use correlational language only (\"tends to\", \"lines up with\") — never \"caused\" or \"because\". Do NOT change, add, or remove any number. No markdown, no emojis."
        var refined: [String] = []
        for sentence in base {
            if let text = await generateText(instructions: instructions, prompt: sentence),
               Self.preservesNumbers(of: sentence, in: text) {
                refined.append(text)
            } else {
                refined.append(sentence)
            }
        }
        AppLog.ai.notice("connections backend=foundationModels count=\(refined.count, privacy: .public) (numbers deterministic, prose only from LLM)")
        return refined
    }

    nonisolated func generateTodayConnection(
        checkIn: DailyCheckIn,
        todayHealth: HealthSnapshot?,
        correlations: [Correlation]
    ) async throws -> String? {
        let base = ConnectionNarrator.todayConnection(
            checkIn: checkIn,
            todayHealth: todayHealth,
            correlations: correlations
        )
        guard let base, isModelAvailable else {
            AppLog.ai.notice("todayConnection backend=heuristic present=\(base != nil ? "yes" : "no", privacy: .public)")
            return base
        }
        let instructions = "You rephrase one factual sentence linking today's health metric to today's mood, keeping it warm, honest, and under 28 words. Use correlational language only (\"tends to\", \"lines up with\") — never \"caused\" or \"because\". Do NOT change, add, or remove any number. No markdown, no emojis."
        if let text = await generateText(instructions: instructions, prompt: base),
           Self.preservesNumbers(of: base, in: text) {
            AppLog.ai.notice("todayConnection backend=foundationModels (numbers deterministic, prose only from LLM)")
            return text
        }
        AppLog.ai.notice("todayConnection backend=heuristic")
        return base
    }

    /// Guards the no-hallucinated-numbers contract: the LLM output must not introduce any digit
    /// sequence that wasn't in the deterministic source sentence.
    private static func preservesNumbers(of source: String, in candidate: String) -> Bool {
        func numbers(_ s: String) -> Set<String> {
            Set(s.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty })
        }
        return numbers(candidate).isSubset(of: numbers(source))
    }

    // MARK: - Prompt Builders (anonymized aggregates)

    private static func average(_ values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
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
            "Identify up to 3 behavioral patterns from \(checkIns.count) daily check-ins (1-5 scales, higher is better; Calm 5 = very calm).",
            String(format: "Avg energy: %.1f, focus: %.1f, calm: %.1f, growth: %.1f",
                   average(checkIns.map(\.energyScore)), average(checkIns.map(\.focusScore)),
                   average(checkIns.map(\.stressScore)), average(checkIns.map(\.growthScore))),
            "Each pattern: one concise, human-readable observation.",
        ]
        return lines.joined(separator: "\n")
    }
}
