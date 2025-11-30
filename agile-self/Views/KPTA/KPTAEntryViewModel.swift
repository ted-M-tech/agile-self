//
//  KPTAEntryViewModel.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Draft Models (not persisted)

/// Represents a draft KPTA item before saving
struct DraftKPTAItem: Identifiable, Equatable {
    let id: UUID
    var text: String
    var category: KPTACategory

    init(id: UUID = UUID(), text: String = "", category: KPTACategory) {
        self.id = id
        self.text = text
        self.category = category
    }

    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Represents a draft Try item with optional action
struct DraftTryItem: Identifiable, Equatable {
    let id: UUID
    var text: String
    var createAction: Bool
    var actionText: String
    var actionDeadline: Date?
    var showDeadlinePicker: Bool

    init(
        id: UUID = UUID(),
        text: String = "",
        createAction: Bool = false,
        actionText: String = "",
        actionDeadline: Date? = nil,
        showDeadlinePicker: Bool = false
    ) {
        self.id = id
        self.text = text
        self.createAction = createAction
        self.actionText = actionText
        self.actionDeadline = actionDeadline
        self.showDeadlinePicker = showDeadlinePicker
    }

    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasValidAction: Bool {
        createAction && !actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - ViewModel

@Observable
final class KPTAEntryViewModel {
    // MARK: - Retrospective Metadata

    var retroType: RetrospectiveType = .weekly
    var startDate: Date = Calendar.current.startOfWeek(for: Date())
    var endDate: Date = Calendar.current.endOfWeek(for: Date())

    // MARK: - KPTA Items

    var keeps: [DraftKPTAItem] = [DraftKPTAItem(category: .keep)]
    var problems: [DraftKPTAItem] = [DraftKPTAItem(category: .problem)]
    var tries: [DraftTryItem] = [DraftTryItem()]

    // MARK: - UI State

    var isSaving: Bool = false
    var showValidationError: Bool = false
    var validationErrorMessage: String = ""
    var showSuccessMessage: Bool = false

    // MARK: - Computed Properties

    var generatedTitle: String {
        Retrospective.generateTitle(for: retroType, startDate: startDate, endDate: endDate)
    }

    var validKeeps: [DraftKPTAItem] {
        keeps.filter { $0.isValid }
    }

    var validProblems: [DraftKPTAItem] {
        problems.filter { $0.isValid }
    }

    var validTries: [DraftTryItem] {
        tries.filter { $0.isValid }
    }

    var totalItemCount: Int {
        validKeeps.count + validProblems.count + validTries.count
    }

    var actionCount: Int {
        tries.filter { $0.hasValidAction }.count
    }

    var canSave: Bool {
        totalItemCount > 0 && !isSaving
    }

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    // MARK: - Keep Methods

    func addKeep() {
        withAnimation(.easeInOut(duration: 0.2)) {
            keeps.append(DraftKPTAItem(category: .keep))
        }
    }

    func removeKeep(at index: Int) {
        guard keeps.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            keeps.remove(at: index)
        }
    }

    func removeKeep(id: UUID) {
        guard keeps.count > 1, let index = keeps.firstIndex(where: { $0.id == id }) else { return }
        removeKeep(at: index)
    }

    // MARK: - Problem Methods

    func addProblem() {
        withAnimation(.easeInOut(duration: 0.2)) {
            problems.append(DraftKPTAItem(category: .problem))
        }
    }

    func removeProblem(at index: Int) {
        guard problems.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            problems.remove(at: index)
        }
    }

    func removeProblem(id: UUID) {
        guard problems.count > 1, let index = problems.firstIndex(where: { $0.id == id }) else { return }
        removeProblem(at: index)
    }

    // MARK: - Try Methods

    func addTry() {
        withAnimation(.easeInOut(duration: 0.2)) {
            tries.append(DraftTryItem())
        }
    }

    func removeTry(at index: Int) {
        guard tries.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            tries.remove(at: index)
        }
    }

    func removeTry(id: UUID) {
        guard tries.count > 1, let index = tries.firstIndex(where: { $0.id == id }) else { return }
        removeTry(at: index)
    }

    func toggleActionForTry(id: UUID) {
        guard let index = tries.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            tries[index].createAction.toggle()
            if tries[index].createAction && tries[index].actionText.isEmpty {
                // Pre-fill action text with try text as a suggestion
                tries[index].actionText = tries[index].text
            }
        }
    }

    // MARK: - Date Range Methods

    func updateDateRange(for type: RetrospectiveType) {
        retroType = type
        let calendar = Calendar.current
        let today = Date()

        switch type {
        case .weekly:
            startDate = calendar.startOfWeek(for: today)
            endDate = calendar.endOfWeek(for: today)
        case .monthly:
            startDate = calendar.startOfMonth(for: today)
            endDate = calendar.endOfMonth(for: today)
        }
    }

    func selectPreviousPeriod() {
        let calendar = Calendar.current

        switch retroType {
        case .weekly:
            if let newStart = calendar.date(byAdding: .weekOfYear, value: -1, to: startDate) {
                startDate = calendar.startOfWeek(for: newStart)
                endDate = calendar.endOfWeek(for: newStart)
            }
        case .monthly:
            if let newStart = calendar.date(byAdding: .month, value: -1, to: startDate) {
                startDate = calendar.startOfMonth(for: newStart)
                endDate = calendar.endOfMonth(for: newStart)
            }
        }
    }

    func selectNextPeriod() {
        let calendar = Calendar.current

        switch retroType {
        case .weekly:
            if let newStart = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) {
                startDate = calendar.startOfWeek(for: newStart)
                endDate = calendar.endOfWeek(for: newStart)
            }
        case .monthly:
            if let newStart = calendar.date(byAdding: .month, value: 1, to: startDate) {
                startDate = calendar.startOfMonth(for: newStart)
                endDate = calendar.endOfMonth(for: newStart)
            }
        }
    }

    func selectCurrentPeriod() {
        updateDateRange(for: retroType)
    }

    // MARK: - Validation

    func validate() -> Bool {
        if totalItemCount == 0 {
            validationErrorMessage = "Please add at least one item to your retrospective."
            showValidationError = true
            return false
        }

        showValidationError = false
        validationErrorMessage = ""
        return true
    }

    // MARK: - Save

    func save(using modelContext: ModelContext) async -> Bool {
        guard validate() else { return false }

        isSaving = true
        defer { isSaving = false }

        // Create the retrospective
        let retrospective = Retrospective(
            title: generatedTitle,
            type: retroType,
            startDate: startDate,
            endDate: endDate
        )

        // Insert the retrospective first (required for relationship linking)
        modelContext.insert(retrospective)

        // Add Keep items to kptaItems (not the computed 'keeps' property)
        for (index, draft) in validKeeps.enumerated() {
            let item = KPTAItem(
                text: draft.text.trimmingCharacters(in: .whitespacesAndNewlines),
                category: .keep,
                orderIndex: index
            )
            retrospective.kptaItems.append(item)
        }

        // Add Problem items to kptaItems
        for (index, draft) in validProblems.enumerated() {
            let item = KPTAItem(
                text: draft.text.trimmingCharacters(in: .whitespacesAndNewlines),
                category: .problem,
                orderIndex: index
            )
            retrospective.kptaItems.append(item)
        }

        // Add Try items to kptaItems and create actions
        for (index, draft) in validTries.enumerated() {
            let item = KPTAItem(
                text: draft.text.trimmingCharacters(in: .whitespacesAndNewlines),
                category: .try,
                orderIndex: index
            )
            retrospective.kptaItems.append(item)

            // Create action if specified
            if draft.hasValidAction {
                let action = ActionItem(
                    text: draft.actionText.trimmingCharacters(in: .whitespacesAndNewlines),
                    deadline: draft.actionDeadline,
                    fromTryItem: true
                )
                retrospective.actions.append(action)
            }
        }

        // Save changes
        do {
            try modelContext.save()
            showSuccessMessage = true
            return true
        } catch {
            validationErrorMessage = "Failed to save retrospective: \(error.localizedDescription)"
            showValidationError = true
            return false
        }
    }

    // MARK: - Reset

    func reset() {
        retroType = .weekly
        updateDateRange(for: .weekly)
        keeps = [DraftKPTAItem(category: .keep)]
        problems = [DraftKPTAItem(category: .problem)]
        tries = [DraftTryItem()]
        showValidationError = false
        validationErrorMessage = ""
        showSuccessMessage = false
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }

    func endOfWeek(for date: Date) -> Date {
        let startOfWeek = startOfWeek(for: date)
        return self.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
    }

    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }

    func endOfMonth(for date: Date) -> Date {
        guard let startOfNextMonth = self.date(byAdding: .month, value: 1, to: startOfMonth(for: date)) else {
            return date
        }
        return self.date(byAdding: .day, value: -1, to: startOfNextMonth) ?? date
    }
}
