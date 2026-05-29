//
//  ProfileViewModel.swift
//  agile-self
//
//  ViewModel for the Profile tab.
//  Manages user profile, streak, and action items.
//

import Foundation
import SwiftData

@Observable
final class ProfileViewModel {

    // MARK: - Published State

    var profile: UserProfile?
    var streak: Streak?
    var actions: [ActionItemV2] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Services

    private var streakService: StreakService?
    private var subscriptionService: SubscriptionService?

    // MARK: - Init

    init(
        streakService: StreakService? = nil,
        subscriptionService: SubscriptionService? = nil
    ) {
        self.streakService = streakService
        self.subscriptionService = subscriptionService
    }

    // MARK: - Configure Services

    func configure(
        streakService: StreakService,
        subscriptionService: SubscriptionService
    ) {
        self.streakService = streakService
        self.subscriptionService = subscriptionService
    }

    // MARK: - Computed

    var activeActions: [ActionItemV2] {
        actions.filter { !$0.isCompleted }
    }

    var completedActions: [ActionItemV2] {
        actions.filter { $0.isCompleted }
    }

    // MARK: - Load Data

    func loadData(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Fetch user profile
            let profileDescriptor = FetchDescriptor<UserProfile>()
            profile = try context.fetch(profileDescriptor).first

            // Fetch streak
            if let streakService {
                streak = streakService.fetchOrCreateStreak(context: context)
            } else {
                let streakDescriptor = FetchDescriptor<Streak>()
                streak = try context.fetch(streakDescriptor).first
            }

            // Fetch action items sorted by creation date
            let actionDescriptor = FetchDescriptor<ActionItemV2>(
                sortBy: [
                    SortDescriptor(\.createdAt, order: .reverse)
                ]
            )
            actions = try context.fetch(actionDescriptor)
        } catch {
            errorMessage = "Unable to load profile. Please try restarting the app."
        }
    }

    // MARK: - Actions

    /// Toggles completion and persists it. Without an explicit save the change relied on
    /// implicit autosave and could be lost; this also refreshes the active/completed split.
    func toggleAction(_ action: ActionItemV2, context: ModelContext) {
        action.toggleCompletion()
        do {
            try context.save()
            reloadActions(context: context)
        } catch {
            errorMessage = "Unable to update the action. Please try again."
        }
    }

    /// Creates a new manual action item and persists it, then refreshes the list.
    func addAction(text: String, priority: ActionPriority, deadline: Date?, context: ModelContext) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let action = ActionItemV2(
            text: trimmed,
            deadline: deadline,
            priority: priority,
            source: .manual
        )
        context.insert(action)
        do {
            try context.save()
            reloadActions(context: context)
        } catch {
            errorMessage = "Unable to save the action. Please try again."
        }
    }

    /// Deletes an action item and persists the change, then refreshes the list.
    func deleteAction(_ action: ActionItemV2, context: ModelContext) {
        context.delete(action)
        do {
            try context.save()
            reloadActions(context: context)
        } catch {
            errorMessage = "Unable to delete the action. Please try again."
        }
    }

    /// Refreshes just the action list without toggling loading/error state.
    private func reloadActions(context: ModelContext) {
        let descriptor = FetchDescriptor<ActionItemV2>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        actions = (try? context.fetch(descriptor)) ?? actions
    }
}
