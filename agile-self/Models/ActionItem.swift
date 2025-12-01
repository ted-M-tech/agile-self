//
//  ActionItem.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftData

@Model
final class ActionItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isCompleted: Bool
    var deadline: Date?
    var completedAt: Date?
    var fromTryItem: Bool
    var priority: ActionPriority
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    /// The retrospective this action belongs to
    var retrospective: Retrospective?

    /// The source Try item this action was derived from (optional)
    /// Note: This is a soft reference - we store the KPTAItem but don't enforce cascade delete
    var sourceKPTAItem: KPTAItem?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        deadline: Date? = nil,
        completedAt: Date? = nil,
        fromTryItem: Bool = false,
        priority: ActionPriority = .medium,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.deadline = deadline
        self.completedAt = completedAt
        self.fromTryItem = fromTryItem
        self.priority = priority
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Overdue Status

    var isOverdue: Bool {
        guard let deadline = deadline, !isCompleted else { return false }
        return deadline < Date()
    }

    /// Returns true if the action is due within the specified number of days
    func isDueSoon(withinDays days: Int = 3) -> Bool {
        guard let deadline = deadline, !isCompleted else { return false }
        guard let daysRemaining = daysUntilDeadline else { return false }
        return daysRemaining >= 0 && daysRemaining <= days
    }

    // MARK: - Completion Management

    func markCompleted() {
        isCompleted = true
        completedAt = Date()
        touch()
    }

    func markIncomplete() {
        isCompleted = false
        completedAt = nil
        touch()
    }

    /// Toggle completion status
    func toggleCompletion() {
        if isCompleted {
            markIncomplete()
        } else {
            markCompleted()
        }
    }

    // MARK: - Validation

    /// Returns true if the action item has valid content
    var isValid: Bool {
        !trimmedText.isEmpty
    }

    /// Returns the text with leading/trailing whitespace removed
    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Updates the text with validated content
    func updateText(_ newText: String) {
        text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        touch()
    }

    /// Returns true if the deadline is set and in the future
    var hasValidDeadline: Bool {
        guard let deadline = deadline else { return false }
        return deadline > Date()
    }

    /// Returns the number of days until the deadline (negative if overdue)
    var daysUntilDeadline: Int? {
        guard let deadline = deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }

    // MARK: - Deadline Helpers

    /// Returns true if the action has a deadline set
    var hasDeadline: Bool {
        deadline != nil
    }

    /// Returns the deadline relative description (e.g., "Due in 3 days", "Overdue by 2 days")
    var deadlineDescription: String? {
        guard let days = daysUntilDeadline else { return nil }

        if days < 0 {
            let overdueDays = abs(days)
            return overdueDays == 1 ? "Overdue by 1 day" : "Overdue by \(overdueDays) days"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(days) days"
        }
    }

    // MARK: - Priority Helpers

    /// Update priority with automatic timestamp update
    func updatePriority(_ newPriority: ActionPriority) {
        priority = newPriority
        touch()
    }

    // MARK: - Notes Helpers

    /// Returns true if the action has notes
    var hasNotes: Bool {
        guard let notes = notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Update notes with automatic timestamp update
    func updateNotes(_ newNotes: String?) {
        notes = newNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
        touch()
    }

    // MARK: - Update Timestamp

    /// Updates the updatedAt timestamp to the current time
    func touch() {
        updatedAt = Date()
    }

    // MARK: - Source Item Helpers

    /// Returns true if this action was derived from a Try item
    var isDerivedFromTry: Bool {
        fromTryItem || sourceKPTAItem != nil
    }

    /// Returns the source Try item's text if available
    var sourceItemText: String? {
        sourceKPTAItem?.text
    }
}
