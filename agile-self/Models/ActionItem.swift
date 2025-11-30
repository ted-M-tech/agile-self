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
    var createdAt: Date

    var retrospective: Retrospective?

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        deadline: Date? = nil,
        completedAt: Date? = nil,
        fromTryItem: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.deadline = deadline
        self.completedAt = completedAt
        self.fromTryItem = fromTryItem
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        guard let deadline = deadline, !isCompleted else { return false }
        return deadline < Date()
    }

    func markCompleted() {
        isCompleted = true
        completedAt = Date()
    }

    func markIncomplete() {
        isCompleted = false
        completedAt = nil
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
}
