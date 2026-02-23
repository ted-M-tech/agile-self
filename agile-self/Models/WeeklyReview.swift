//
//  WeeklyReview.swift
//  agile-self
//
//  Created by Claude on 2026/02/22.
//

import Foundation
import SwiftData

// MARK: - Supporting Types (must be top-level, not nested inside @Model)

/// The role of a message in the AI coaching conversation.
enum MessageRole: String, Codable {
    case user
    case assistant
}

/// A single message in the weekly review coaching conversation.
struct ConversationMessage: Codable, Identifiable {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - WeeklyReview Model

/// A weekly reflection that combines AI-guided conversation with structured wins/challenges.
@Model
final class WeeklyReview {

    // MARK: - Persisted Properties

    @Attribute(.unique) var id: UUID
    /// Monday (or configured start day) of the review week.
    var weekStart: Date
    /// Sunday (or configured end day) of the review week.
    var weekEnd: Date
    /// JSON-encoded array of ConversationMessage for the AI coaching chat.
    var conversationJSON: Data?
    /// Key wins identified during the week.
    var wins: [String]
    /// Challenges or blockers encountered during the week.
    var challenges: [String]
    /// AI-generated summary of the week.
    var summary: String?
    /// AI-generated key takeaway for the upcoming week.
    var aiTakeaway: String?
    /// Whether the user has completed the review flow.
    var isCompleted: Bool
    var createdAt: Date
    /// Timestamp when the review was marked complete.
    var completedAt: Date?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        weekStart: Date,
        weekEnd: Date,
        conversationJSON: Data? = nil,
        wins: [String] = [],
        challenges: [String] = [],
        summary: String? = nil,
        aiTakeaway: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.conversationJSON = conversationJSON
        self.wins = wins
        self.challenges = challenges
        self.summary = summary
        self.aiTakeaway = aiTakeaway
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    // MARK: - Conversation Helpers

    /// Decodes the conversation messages from JSON. Returns an empty array on failure.
    var conversations: [ConversationMessage] {
        guard let data = conversationJSON else { return [] }
        return (try? JSONDecoder().decode([ConversationMessage].self, from: data)) ?? []
    }

    /// Encodes and persists the conversation messages as JSON.
    func setConversations(_ messages: [ConversationMessage]) {
        conversationJSON = try? JSONEncoder().encode(messages)
    }
}
