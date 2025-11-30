//
//  Retrospective.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftData

@Model
final class Retrospective {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: RetrospectiveType
    var startDate: Date
    var endDate: Date

    // Single relationship to all KPTA items - use computed properties to filter by category
    @Relationship(deleteRule: .cascade, inverse: \KPTAItem.retrospective)
    var kptaItems: [KPTAItem]

    @Relationship(deleteRule: .cascade, inverse: \ActionItem.retrospective)
    var actions: [ActionItem]

    @Relationship(deleteRule: .cascade, inverse: \HealthSummary.retrospective)
    var healthSummary: HealthSummary?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        type: RetrospectiveType,
        startDate: Date,
        endDate: Date,
        kptaItems: [KPTAItem] = [],
        actions: [ActionItem] = [],
        healthSummary: HealthSummary? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.kptaItems = kptaItems
        self.actions = actions
        self.healthSummary = healthSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Category-Filtered Accessors

    var keeps: [KPTAItem] {
        kptaItems.filter { $0.category == .keep }.sorted { $0.orderIndex < $1.orderIndex }
    }

    var problems: [KPTAItem] {
        kptaItems.filter { $0.category == .problem }.sorted { $0.orderIndex < $1.orderIndex }
    }

    var tries: [KPTAItem] {
        kptaItems.filter { $0.category == .try }.sorted { $0.orderIndex < $1.orderIndex }
    }

    // MARK: - KPTA Item Management

    func addKeep(_ text: String) -> KPTAItem {
        let item = KPTAItem(text: text, category: .keep, orderIndex: keeps.count)
        kptaItems.append(item)
        touch()
        return item
    }

    func addProblem(_ text: String) -> KPTAItem {
        let item = KPTAItem(text: text, category: .problem, orderIndex: problems.count)
        kptaItems.append(item)
        touch()
        return item
    }

    func addTry(_ text: String) -> KPTAItem {
        let item = KPTAItem(text: text, category: .try, orderIndex: tries.count)
        kptaItems.append(item)
        touch()
        return item
    }

    func removeKPTAItem(_ item: KPTAItem) {
        kptaItems.removeAll { $0.id == item.id }
        touch()
    }

    // MARK: - Action Item Management

    func addAction(_ text: String, deadline: Date? = nil, fromTryItem: Bool = false) -> ActionItem {
        let item = ActionItem(text: text, deadline: deadline, fromTryItem: fromTryItem)
        actions.append(item)
        touch()
        return item
    }

    func removeAction(_ item: ActionItem) {
        actions.removeAll { $0.id == item.id }
        touch()
    }

    // MARK: - Computed Properties

    var pendingActionsCount: Int {
        actions.filter { !$0.isCompleted }.count
    }

    var completedActionsCount: Int {
        actions.filter { $0.isCompleted }.count
    }

    var actionCompletionRate: Double {
        guard !actions.isEmpty else { return 0 }
        return Double(completedActionsCount) / Double(actions.count)
    }

    var totalKPTACount: Int {
        kptaItems.count
    }

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    // MARK: - Helper Methods

    static func generateTitle(for type: RetrospectiveType, startDate: Date, endDate: Date) -> String {
        let formatter = DateFormatter()

        switch type {
        case .weekly:
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: startDate))"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: startDate)
        }
    }

    func touch() {
        updatedAt = Date()
    }

    // MARK: - Validation

    /// Validates that the retrospective has valid data
    var isValid: Bool {
        // Title must not be empty
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // Date range must be valid
        guard startDate <= endDate else {
            return false
        }

        // Must have at least one KPTA item
        guard !kptaItems.isEmpty else {
            return false
        }

        return true
    }

    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title cannot be empty")
        }

        if startDate > endDate {
            errors.append("End date must be after start date")
        }

        if kptaItems.isEmpty {
            errors.append("At least one Keep, Problem, or Try item is required")
        }

        return errors
    }

    /// Returns the count of valid KPTA items (with non-empty text)
    var validKPTACount: Int {
        kptaItems.filter { $0.isValid }.count
    }

    /// Returns the count of valid actions (with non-empty text)
    var validActionsCount: Int {
        actions.filter { $0.isValid }.count
    }

    /// Returns overdue action items
    var overdueActions: [ActionItem] {
        actions.filter { $0.isOverdue }
    }

    /// Returns the number of days in the retrospective period
    var periodDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}
