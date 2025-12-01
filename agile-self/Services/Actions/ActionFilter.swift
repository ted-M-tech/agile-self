//
//  ActionFilter.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation

/// Filter criteria for querying ActionItems
/// Used with ActionService to retrieve filtered lists of actions
struct ActionFilter: Sendable {

    // MARK: - Completion Status

    /// Filter by completion status
    enum CompletionStatus: Sendable {
        case all
        case completed
        case incomplete
    }

    var completionStatus: CompletionStatus = .all

    // MARK: - Date Range

    /// Filter by deadline within date range
    var deadlineStartDate: Date?
    var deadlineEndDate: Date?

    /// Filter by creation date within range
    var createdStartDate: Date?
    var createdEndDate: Date?

    // MARK: - Priority

    /// Filter by specific priorities (empty = all priorities)
    var priorities: Set<ActionPriority> = []

    // MARK: - Retrospective

    /// Filter by specific retrospective
    var retrospectiveId: UUID?

    // MARK: - Overdue Status

    /// Filter for overdue items only
    var overdueOnly: Bool = false

    // MARK: - Source

    /// Filter for actions derived from Try items only
    var fromTryItemOnly: Bool = false

    // MARK: - Sorting

    /// Sort order for results
    enum SortOrder: Sendable {
        case createdAtAscending
        case createdAtDescending
        case deadlineAscending
        case deadlineDescending
        case priorityHighToLow
        case priorityLowToHigh
        case updatedAtDescending
    }

    var sortOrder: SortOrder = .createdAtDescending

    // MARK: - Initialization

    init(
        completionStatus: CompletionStatus = .all,
        deadlineStartDate: Date? = nil,
        deadlineEndDate: Date? = nil,
        createdStartDate: Date? = nil,
        createdEndDate: Date? = nil,
        priorities: Set<ActionPriority> = [],
        retrospectiveId: UUID? = nil,
        overdueOnly: Bool = false,
        fromTryItemOnly: Bool = false,
        sortOrder: SortOrder = .createdAtDescending
    ) {
        self.completionStatus = completionStatus
        self.deadlineStartDate = deadlineStartDate
        self.deadlineEndDate = deadlineEndDate
        self.createdStartDate = createdStartDate
        self.createdEndDate = createdEndDate
        self.priorities = priorities
        self.retrospectiveId = retrospectiveId
        self.overdueOnly = overdueOnly
        self.fromTryItemOnly = fromTryItemOnly
        self.sortOrder = sortOrder
    }

    // MARK: - Convenience Factory Methods

    /// Filter for all incomplete actions
    static var incomplete: ActionFilter {
        ActionFilter(completionStatus: .incomplete)
    }

    /// Filter for all completed actions
    static var completed: ActionFilter {
        ActionFilter(completionStatus: .completed)
    }

    /// Filter for overdue incomplete actions
    static var overdue: ActionFilter {
        ActionFilter(completionStatus: .incomplete, overdueOnly: true)
    }

    /// Filter for high priority incomplete actions
    static var highPriority: ActionFilter {
        ActionFilter(
            completionStatus: .incomplete,
            priorities: [.high],
            sortOrder: .deadlineAscending
        )
    }

    /// Filter for actions derived from Try items
    static var fromTry: ActionFilter {
        ActionFilter(fromTryItemOnly: true)
    }

    /// Filter for a specific retrospective
    static func forRetrospective(_ id: UUID) -> ActionFilter {
        ActionFilter(retrospectiveId: id)
    }

    /// Filter for actions due within the next N days
    static func dueSoon(days: Int = 7) -> ActionFilter {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        return ActionFilter(
            completionStatus: .incomplete,
            deadlineStartDate: now,
            deadlineEndDate: futureDate,
            sortOrder: .deadlineAscending
        )
    }

    /// Filter for actions created in a date range
    static func createdBetween(start: Date, end: Date) -> ActionFilter {
        ActionFilter(
            createdStartDate: start,
            createdEndDate: end,
            sortOrder: .createdAtDescending
        )
    }
}

// MARK: - Filter Application

extension ActionFilter {

    /// Apply this filter to an array of ActionItems
    /// This is useful for client-side filtering when not using SwiftData queries
    func apply(to actions: [ActionItem]) -> [ActionItem] {
        var result = actions

        // Filter by completion status
        switch completionStatus {
        case .all:
            break
        case .completed:
            result = result.filter { $0.isCompleted }
        case .incomplete:
            result = result.filter { !$0.isCompleted }
        }

        // Filter by deadline date range
        if let start = deadlineStartDate {
            result = result.filter { action in
                guard let deadline = action.deadline else { return false }
                return deadline >= start
            }
        }
        if let end = deadlineEndDate {
            result = result.filter { action in
                guard let deadline = action.deadline else { return false }
                return deadline <= end
            }
        }

        // Filter by creation date range
        if let start = createdStartDate {
            result = result.filter { $0.createdAt >= start }
        }
        if let end = createdEndDate {
            result = result.filter { $0.createdAt <= end }
        }

        // Filter by priorities
        if !priorities.isEmpty {
            result = result.filter { priorities.contains($0.priority) }
        }

        // Filter by retrospective
        if let retroId = retrospectiveId {
            result = result.filter { $0.retrospective?.id == retroId }
        }

        // Filter by overdue status
        if overdueOnly {
            result = result.filter { $0.isOverdue }
        }

        // Filter by source (from Try item)
        if fromTryItemOnly {
            result = result.filter { $0.fromTryItem }
        }

        // Apply sorting
        result = sortActions(result)

        return result
    }

    private func sortActions(_ actions: [ActionItem]) -> [ActionItem] {
        switch sortOrder {
        case .createdAtAscending:
            return actions.sorted { $0.createdAt < $1.createdAt }

        case .createdAtDescending:
            return actions.sorted { $0.createdAt > $1.createdAt }

        case .deadlineAscending:
            return actions.sorted { lhs, rhs in
                switch (lhs.deadline, rhs.deadline) {
                case (nil, nil):
                    return lhs.createdAt < rhs.createdAt
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case let (lhsDate?, rhsDate?):
                    return lhsDate < rhsDate
                }
            }

        case .deadlineDescending:
            return actions.sorted { lhs, rhs in
                switch (lhs.deadline, rhs.deadline) {
                case (nil, nil):
                    return lhs.createdAt > rhs.createdAt
                case (nil, _):
                    return true
                case (_, nil):
                    return false
                case let (lhsDate?, rhsDate?):
                    return lhsDate > rhsDate
                }
            }

        case .priorityHighToLow:
            return actions.sorted { $0.priority < $1.priority }

        case .priorityLowToHigh:
            return actions.sorted { $0.priority > $1.priority }

        case .updatedAtDescending:
            return actions.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}

// MARK: - Equatable

extension ActionFilter: Equatable {
    static func == (lhs: ActionFilter, rhs: ActionFilter) -> Bool {
        lhs.completionStatus == rhs.completionStatus &&
        lhs.deadlineStartDate == rhs.deadlineStartDate &&
        lhs.deadlineEndDate == rhs.deadlineEndDate &&
        lhs.createdStartDate == rhs.createdStartDate &&
        lhs.createdEndDate == rhs.createdEndDate &&
        lhs.priorities == rhs.priorities &&
        lhs.retrospectiveId == rhs.retrospectiveId &&
        lhs.overdueOnly == rhs.overdueOnly &&
        lhs.fromTryItemOnly == rhs.fromTryItemOnly &&
        lhs.sortOrder == rhs.sortOrder
    }
}

extension ActionFilter.CompletionStatus: Equatable {}
extension ActionFilter.SortOrder: Equatable {}
