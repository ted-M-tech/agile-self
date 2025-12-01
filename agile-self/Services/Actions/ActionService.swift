//
//  ActionService.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftData

/// Service for managing ActionItem CRUD operations and queries
/// Designed to work with SwiftData and CloudKit sync
@MainActor
final class ActionService {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new action item
    /// - Parameters:
    ///   - text: The action text
    ///   - deadline: Optional deadline date
    ///   - priority: Priority level (defaults to medium)
    ///   - fromTryItem: Whether this action is derived from a Try item
    ///   - retrospective: Optional parent retrospective
    ///   - sourceKPTAItem: Optional source Try item
    ///   - notes: Optional additional notes
    /// - Returns: The created ActionItem
    @discardableResult
    func createAction(
        text: String,
        deadline: Date? = nil,
        priority: ActionPriority = .medium,
        fromTryItem: Bool = false,
        retrospective: Retrospective? = nil,
        sourceKPTAItem: KPTAItem? = nil,
        notes: String? = nil
    ) -> ActionItem {
        let action = ActionItem(
            text: text,
            deadline: deadline,
            fromTryItem: fromTryItem || sourceKPTAItem != nil,
            priority: priority,
            notes: notes
        )

        action.retrospective = retrospective
        action.sourceKPTAItem = sourceKPTAItem

        modelContext.insert(action)

        // Also add to retrospective's actions array if provided
        if let retro = retrospective {
            retro.actions.append(action)
            retro.touch()
        }

        return action
    }

    /// Create an action from a Try item
    /// - Parameters:
    ///   - tryItem: The source KPTAItem (should be a Try item)
    ///   - text: Optional custom text (defaults to Try item's text)
    ///   - deadline: Optional deadline
    ///   - priority: Priority level
    ///   - retrospective: Optional parent retrospective
    ///   - notes: Optional notes
    /// - Returns: The created ActionItem
    @discardableResult
    func createActionFromTry(
        _ tryItem: KPTAItem,
        text: String? = nil,
        deadline: Date? = nil,
        priority: ActionPriority = .medium,
        retrospective: Retrospective? = nil,
        notes: String? = nil
    ) -> ActionItem {
        return createAction(
            text: text ?? tryItem.text,
            deadline: deadline,
            priority: priority,
            fromTryItem: true,
            retrospective: retrospective ?? tryItem.retrospective,
            sourceKPTAItem: tryItem,
            notes: notes
        )
    }

    // MARK: - Update

    /// Update an action item's properties
    /// - Parameters:
    ///   - action: The action to update
    ///   - text: New text (nil = no change)
    ///   - deadline: New deadline (nil = no change, use .some(nil) to clear)
    ///   - priority: New priority (nil = no change)
    ///   - notes: New notes (nil = no change, use .some(nil) to clear)
    func updateAction(
        _ action: ActionItem,
        text: String? = nil,
        deadline: Date?? = nil,
        priority: ActionPriority? = nil,
        notes: String?? = nil
    ) {
        if let newText = text {
            action.updateText(newText)
        }

        if let newDeadline = deadline {
            action.deadline = newDeadline
            action.touch()
        }

        if let newPriority = priority {
            action.updatePriority(newPriority)
        }

        if let newNotes = notes {
            action.updateNotes(newNotes)
        }
    }

    // MARK: - Delete

    /// Delete an action item
    /// - Parameter action: The action to delete
    func deleteAction(_ action: ActionItem) {
        // Remove from retrospective's array first
        if let retro = action.retrospective {
            retro.removeAction(action)
        }

        modelContext.delete(action)
    }

    /// Delete multiple action items
    /// - Parameter actions: The actions to delete
    func deleteActions(_ actions: [ActionItem]) {
        for action in actions {
            deleteAction(action)
        }
    }

    // MARK: - Toggle Completion

    /// Toggle the completion status of an action
    /// - Parameter action: The action to toggle
    func toggleCompletion(_ action: ActionItem) {
        action.toggleCompletion()
    }

    /// Mark an action as completed
    /// - Parameter action: The action to complete
    func markCompleted(_ action: ActionItem) {
        action.markCompleted()
    }

    /// Mark an action as incomplete
    /// - Parameter action: The action to mark incomplete
    func markIncomplete(_ action: ActionItem) {
        action.markIncomplete()
    }

    // MARK: - Fetch with Filter

    /// Fetch actions using a filter
    /// - Parameter filter: The filter criteria
    /// - Returns: Array of matching ActionItems
    func fetchActions(filter: ActionFilter = ActionFilter()) throws -> [ActionItem] {
        // Build the base descriptor
        var descriptor = FetchDescriptor<ActionItem>()

        // Build predicate based on filter
        var predicates: [Predicate<ActionItem>] = []

        // Completion status predicate
        switch filter.completionStatus {
        case .all:
            break
        case .completed:
            predicates.append(#Predicate<ActionItem> { $0.isCompleted == true })
        case .incomplete:
            predicates.append(#Predicate<ActionItem> { $0.isCompleted == false })
        }

        // Retrospective predicate
        if let retroId = filter.retrospectiveId {
            predicates.append(#Predicate<ActionItem> { $0.retrospective?.id == retroId })
        }

        // From Try item predicate
        if filter.fromTryItemOnly {
            predicates.append(#Predicate<ActionItem> { $0.fromTryItem == true })
        }

        // Combine predicates if any
        if !predicates.isEmpty {
            // Combine all predicates with AND
            let combinedPredicate = predicates.reduce(#Predicate<ActionItem> { _ in true }) { combined, next in
                #Predicate<ActionItem> { action in
                    combined.evaluate(action) && next.evaluate(action)
                }
            }
            descriptor.predicate = combinedPredicate
        }

        // Apply sort order
        switch filter.sortOrder {
        case .createdAtAscending:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        case .createdAtDescending:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        case .updatedAtDescending:
            descriptor.sortBy = [SortDescriptor(\.updatedAt, order: .reverse)]
        default:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        }

        // Fetch from database
        let actions = try modelContext.fetch(descriptor)

        // Apply client-side filters that can't be done with predicates
        // (date ranges, priorities, overdue status)
        return filter.apply(to: actions)
    }

    // MARK: - Convenience Fetch Methods

    /// Fetch all overdue actions
    /// - Returns: Array of overdue ActionItems sorted by deadline
    func fetchOverdueActions() throws -> [ActionItem] {
        return try fetchActions(filter: .overdue)
    }

    /// Fetch upcoming actions due within the specified number of days
    /// - Parameter days: Number of days to look ahead
    /// - Returns: Array of ActionItems due soon
    func fetchUpcomingActions(days: Int = 7) throws -> [ActionItem] {
        return try fetchActions(filter: .dueSoon(days: days))
    }

    /// Fetch all incomplete actions
    /// - Returns: Array of incomplete ActionItems
    func fetchIncompleteActions() throws -> [ActionItem] {
        return try fetchActions(filter: .incomplete)
    }

    /// Fetch all completed actions
    /// - Returns: Array of completed ActionItems
    func fetchCompletedActions() throws -> [ActionItem] {
        return try fetchActions(filter: .completed)
    }

    /// Fetch high priority incomplete actions
    /// - Returns: Array of high priority ActionItems
    func fetchHighPriorityActions() throws -> [ActionItem] {
        return try fetchActions(filter: .highPriority)
    }

    /// Fetch actions for a specific retrospective
    /// - Parameter retrospective: The retrospective to fetch actions for
    /// - Returns: Array of ActionItems belonging to the retrospective
    func fetchActions(for retrospective: Retrospective) throws -> [ActionItem] {
        return try fetchActions(filter: .forRetrospective(retrospective.id))
    }

    /// Fetch actions derived from Try items
    /// - Returns: Array of ActionItems that were derived from Try items
    func fetchActionsFromTry() throws -> [ActionItem] {
        return try fetchActions(filter: .fromTry)
    }

    // MARK: - Statistics

    /// Get action statistics
    /// - Parameter filter: Optional filter to scope statistics
    /// - Returns: ActionStatistics object
    func getStatistics(filter: ActionFilter = ActionFilter()) throws -> ActionStatistics {
        let actions = try fetchActions(filter: filter)

        let total = actions.count
        let completed = actions.filter { $0.isCompleted }.count
        let incomplete = total - completed
        let overdue = actions.filter { $0.isOverdue }.count

        let highPriority = actions.filter { $0.priority == .high && !$0.isCompleted }.count
        let mediumPriority = actions.filter { $0.priority == .medium && !$0.isCompleted }.count
        let lowPriority = actions.filter { $0.priority == .low && !$0.isCompleted }.count

        let fromTry = actions.filter { $0.fromTryItem }.count

        let completionRate = total > 0 ? Double(completed) / Double(total) : 0

        return ActionStatistics(
            total: total,
            completed: completed,
            incomplete: incomplete,
            overdue: overdue,
            highPriority: highPriority,
            mediumPriority: mediumPriority,
            lowPriority: lowPriority,
            fromTry: fromTry,
            completionRate: completionRate
        )
    }

    // MARK: - Batch Operations

    /// Mark multiple actions as completed
    /// - Parameter actions: The actions to complete
    func markAllCompleted(_ actions: [ActionItem]) {
        for action in actions {
            action.markCompleted()
        }
    }

    /// Mark multiple actions as incomplete
    /// - Parameter actions: The actions to mark incomplete
    func markAllIncomplete(_ actions: [ActionItem]) {
        for action in actions {
            action.markIncomplete()
        }
    }

    /// Delete all completed actions
    func deleteCompletedActions() throws {
        let completed = try fetchCompletedActions()
        deleteActions(completed)
    }

    // MARK: - Save

    /// Explicitly save the model context
    /// Note: SwiftData typically auto-saves, but this can be called for immediate persistence
    func save() throws {
        try modelContext.save()
    }
}

// MARK: - Action Statistics

/// Statistics about action items
struct ActionStatistics: Sendable, Equatable {
    let total: Int
    let completed: Int
    let incomplete: Int
    let overdue: Int
    let highPriority: Int
    let mediumPriority: Int
    let lowPriority: Int
    let fromTry: Int
    let completionRate: Double

    /// Formatted completion rate as percentage string
    var formattedCompletionRate: String {
        String(format: "%.0f%%", completionRate * 100)
    }
}
