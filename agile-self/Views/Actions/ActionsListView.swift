//
//  ActionsListView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// Filter options for action items display in the list view
enum ActionListFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .active: return "circle"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

/// Sort options for action items
enum ActionSort: String, CaseIterable, Identifiable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case createdDate = "Created"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dueDate: return "calendar"
        case .priority: return "exclamationmark.3"
        case .createdDate: return "clock"
        }
    }
}

/// Main view showing all action items with filtering and sorting
struct ActionsListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ActionItem.createdAt, order: .reverse)
    private var allActions: [ActionItem]

    @State private var selectedFilter: ActionListFilter = .active
    @State private var selectedSort: ActionSort = .dueDate
    @State private var showAddSheet = false
    @State private var selectedAction: ActionItem?
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            Group {
                if allActions.isEmpty {
                    emptyState
                } else {
                    actionsList
                }
            }
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.KPTA.action)
                    }
                    .accessibilityLabel("Add new action")
                }

                ToolbarItem(placement: .secondaryAction) {
                    sortMenu
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddActionView()
            }
            .sheet(item: $selectedAction) { action in
                ActionDetailView(action: action)
            }
        }
    }

    // MARK: - Actions List

    private var actionsList: some View {
        VStack(spacing: 0) {
            // Filter Picker
            filterPicker
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)

            // Summary Header
            if !filteredActions.isEmpty {
                summaryHeader
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.sm)
            }

            // List
            List {
                ForEach(sortedActions) { action in
                    ActionRowView(
                        action: action,
                        onToggleComplete: {
                            toggleCompletion(for: action)
                        },
                        onTap: {
                            selectedAction = action
                        }
                    )
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            toggleCompletion(for: action)
                        } label: {
                            Label(
                                action.isCompleted ? "Undo" : "Complete",
                                systemImage: action.isCompleted ? "arrow.uturn.backward" : "checkmark"
                            )
                        }
                        .tint(action.isCompleted ? .orange : .green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteAction(action)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await refresh()
            }
        }
    }

    // MARK: - Filter Picker

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(ActionListFilter.allCases) { filter in
                HStack {
                    Image(systemName: filter.iconName)
                    Text(filter.rawValue)
                }
                .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Filter actions")
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(ActionSort.allCases) { sort in
                Button {
                    withAnimation {
                        selectedSort = sort
                    }
                } label: {
                    Label(sort.rawValue, systemImage: sort.iconName)
                    if selectedSort == sort {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort options")
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack {
            Text(summaryText)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if overdueCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text("\(overdueCount) overdue")
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Semantic.overdue)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summaryAccessibilityLabel)
    }

    private var summaryText: String {
        let count = filteredActions.count
        let noun = count == 1 ? "action" : "actions"

        switch selectedFilter {
        case .all:
            return "\(count) \(noun)"
        case .active:
            return "\(count) active \(noun)"
        case .completed:
            return "\(count) completed \(noun)"
        }
    }

    private var summaryAccessibilityLabel: String {
        var label = summaryText
        if overdueCount > 0 {
            label += ", \(overdueCount) overdue"
        }
        return label
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Actions", systemImage: "checkmark.circle")
        } description: {
            Text("Create actions from your retrospectives or add them directly.")
        } actions: {
            Button {
                showAddSheet = true
            } label: {
                Text("Add Action")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.KPTA.action)
        }
    }

    // MARK: - Computed Properties

    private var filteredActions: [ActionItem] {
        switch selectedFilter {
        case .all:
            return allActions
        case .active:
            return allActions.filter { !$0.isCompleted }
        case .completed:
            return allActions.filter { $0.isCompleted }
        }
    }

    private var sortedActions: [ActionItem] {
        switch selectedSort {
        case .dueDate:
            return filteredActions.sorted { action1, action2 in
                // Actions with deadlines come first
                switch (action1.deadline, action2.deadline) {
                case (nil, nil):
                    return action1.createdAt > action2.createdAt
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case let (date1?, date2?):
                    return date1 < date2
                }
            }
        case .priority:
            return filteredActions.sorted { action1, action2 in
                if action1.priority != action2.priority {
                    return action1.priority < action2.priority
                }
                return action1.createdAt > action2.createdAt
            }
        case .createdDate:
            return filteredActions.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private var overdueCount: Int {
        filteredActions.filter { $0.isOverdue }.count
    }

    // MARK: - Actions

    private func toggleCompletion(for action: ActionItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if action.isCompleted {
                action.markIncomplete()
            } else {
                action.markCompleted()
            }
        }
    }

    private func deleteAction(_ action: ActionItem) {
        withAnimation {
            modelContext.delete(action)
        }
    }

    private func refresh() async {
        // Add a slight delay for visual feedback
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// MARK: - Preview

#Preview("With Actions") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self, Retrospective.self, KPTAItem.self, HealthSummary.self,
            configurations: config
        )

        // Add sample actions
        let context = container.mainContext

        let action1 = ActionItem(
            text: "Set up Pomodoro timer and use daily",
            deadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            fromTryItem: true,
            priority: .high
        )

        let action2 = ActionItem(
            text: "Review weekly goals every Monday morning",
            deadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            priority: .medium
        )

        let action3 = ActionItem(
            text: "Complete project documentation",
            deadline: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            priority: .high
        )

        let action4 = ActionItem(
            text: "Exercise for 30 minutes",
            isCompleted: true,
            completedAt: Date(),
            priority: .low
        )

        context.insert(action1)
        context.insert(action2)
        context.insert(action3)
        context.insert(action4)

        return ActionsListView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}

#Preview("Empty State") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self, Retrospective.self, KPTAItem.self, HealthSummary.self,
            configurations: config
        )
        return ActionsListView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
