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

    @Relationship(deleteRule: .cascade, inverse: \KPTAItem.retrospective)
    var keeps: [KPTAItem]

    @Relationship(deleteRule: .cascade, inverse: \KPTAItem.retrospective)
    var problems: [KPTAItem]

    @Relationship(deleteRule: .cascade, inverse: \KPTAItem.retrospective)
    var tries: [KPTAItem]

    @Relationship(deleteRule: .cascade, inverse: \ActionItem.retrospective)
    var actions: [ActionItem]

    var healthSummary: HealthSummary?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        type: RetrospectiveType,
        startDate: Date,
        endDate: Date,
        keeps: [KPTAItem] = [],
        problems: [KPTAItem] = [],
        tries: [KPTAItem] = [],
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
        self.keeps = keeps
        self.problems = problems
        self.tries = tries
        self.actions = actions
        self.healthSummary = healthSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
        keeps.count + problems.count + tries.count
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
}
