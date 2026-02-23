//
//  ActionItemV2.swift
//  agile-self
//
//  Created by Claude on 2026/02/22.
//

import Foundation
import SwiftData

// MARK: - Supporting Types (must be top-level, not nested inside @Model)

/// Where an action item originated from.
enum ActionSource: String, Codable, CaseIterable {
    /// Created during a weekly review session.
    case weeklyReview
    /// Manually created by the user.
    case manual
    /// Suggested by on-device AI analysis.
    case aiSuggested
}

// MARK: - ActionItemV2 Model

/// A v2 action item with source tracking, decoupled from the legacy Retrospective relationship.
@Model
final class ActionItemV2 {

    // MARK: - Persisted Properties

    @Attribute(.unique) var id: UUID
    /// The action text describing what needs to be done.
    var text: String
    /// Whether the action has been completed.
    var isCompleted: Bool
    /// Optional deadline for the action.
    var deadline: Date?
    /// Timestamp when the action was marked complete.
    var completedAt: Date?
    /// Priority level (high, medium, low).
    var priority: ActionPriority
    /// Where this action originated from.
    var source: ActionSource
    /// Optional notes or context for the action.
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        deadline: Date? = nil,
        completedAt: Date? = nil,
        priority: ActionPriority = .medium,
        source: ActionSource = .manual,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.deadline = deadline
        self.completedAt = completedAt
        self.priority = priority
        self.source = source
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Returns true if the action has an unmet deadline in the past.
    var isOverdue: Bool {
        guard let deadline = deadline, !isCompleted else { return false }
        return deadline < Date()
    }

    /// Number of calendar days until the deadline. Negative if overdue. Nil if no deadline.
    var daysUntilDeadline: Int? {
        guard let deadline = deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }

    // MARK: - Methods

    /// Toggles the completion state and updates timestamps.
    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
        updatedAt = Date()
    }
}
