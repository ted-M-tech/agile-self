//
//  ReflectionService.swift
//  agile-self
//
//  On-device AI for the post-check-in reflection chat: a warm, context-aware follow-up
//  question and a one-line "moment worth keeping" summary saved onto the check-in.
//
//  Uses Apple's on-device Foundation Models LLM (iOS 26) when available — verified live on
//  this device — and degrades to graceful, still-useful templates otherwise (e.g. simulator
//  / Apple Intelligence off). Kept SELF-CONTAINED (not part of AIServiceProtocol) so the
//  reflection feature is isolated and never destabilizes the core AI routing.
//

import Foundation
import os

#if canImport(FoundationModels)
import FoundationModels
#endif

final class ReflectionService {

    /// Whether the on-device LLM is usable; cached once. false on simulator / ineligible /
    /// Apple Intelligence off → callers get the template fallbacks.
    let isModelAvailable: Bool

    init() {
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

    /// A short, warm follow-up question reacting to the user's first answer — nudging them to
    /// capture something meaningful (a challenge, a lesson, a step outside their comfort zone).
    func followUp(checkIn: DailyCheckIn, firstAnswer: String) async -> String {
        let trimmed = firstAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "What made that stand out for you?"
        guard !trimmed.isEmpty else { return fallback }

        let instructions = """
        You are a warm, concise reflection coach inside a personal-growth app. The user just \
        logged their day and shared one thing about it. Ask ONE short, specific follow-up \
        question (max 15 words) that invites them to capture a meaningful moment — a challenge \
        they faced, something they learned, or a step outside their comfort zone. No preamble; \
        output only the question.
        """
        let prompt = "Today felt \(moodWord(for: checkIn)). They said: \"\(trimmed)\""
        return await generate(instructions: instructions, prompt: prompt) ?? fallback
    }

    /// Distills the reflection answers into ONE concise, first-person line worth keeping on the
    /// check-in. Falls back to the user's own (trimmed) words when no LLM is available.
    func summarize(checkIn: DailyCheckIn, answers: [String]) async -> String {
        let joined = answers
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " — ")
        guard !joined.isEmpty else { return "" }

        let instructions = """
        You distill a short reflection into ONE first-person sentence (max 22 words) capturing \
        the moment worth remembering from the user's day — especially growth, a challenge met, \
        or stepping outside their comfort zone. Keep their voice and facts. Output only the \
        sentence, with no surrounding quotes.
        """
        let prompt = "Mood: \(moodWord(for: checkIn)). Reflection: \(joined)"
        let result = await generate(instructions: instructions, prompt: prompt)
        return result ?? String(joined.prefix(180))
    }

    // MARK: - Private

    private func moodWord(for checkIn: DailyCheckIn) -> String {
        switch checkIn.compositeScore {
        case 4.5...: return "great"
        case 3.5...: return "good"
        case 2.5...: return "steady"
        case 1.5...: return "tough"
        default: return "hard"
        }
    }

    /// Single-shot on-device generation. Returns nil when unavailable / on throw / empty so the
    /// caller can fall back. Mirrors FoundationModelsAIService's layered guarantees.
    private func generate(instructions: String, prompt: String) async -> String? {
        guard isModelAvailable else { return nil }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            } catch {
                AppLog.ai.notice("reflection generation failed — using fallback")
                return nil
            }
        }
        #endif
        return nil
    }
}
