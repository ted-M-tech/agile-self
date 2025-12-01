//
//  ActionsSummaryWidget.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// A summary widget component for the Dashboard showing action stats
struct ActionsSummaryWidget: View {
    @Query(filter: #Predicate<ActionItem> { !$0.isCompleted })
    private var activeActions: [ActionItem]

    @Query private var allActions: [ActionItem]

    let onTap: () -> Void
    let onAddTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header
                header

                Divider()

                // Stats
                statsRow

                // Overdue Warning
                if overdueCount > 0 {
                    overdueWarning
                }

                // Quick Actions
                quickAddButton
            }
            .padding(Theme.Spacing.md)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.KPTA.action.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view all actions")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "checklist")
                .font(.title2)
                .foregroundStyle(Theme.KPTA.action)
                .accessibilityHidden(true)

            Text("Actions")
                .font(Theme.Typography.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Active Count
            statItem(
                value: activeCount,
                label: "Active",
                color: Theme.KPTA.action
            )

            // Completed Today
            statItem(
                value: completedTodayCount,
                label: "Done Today",
                color: Theme.Semantic.completed
            )

            // Completion Rate
            if allActions.count > 0 {
                statItem(
                    value: completionPercentage,
                    label: "Complete",
                    color: completionColor,
                    isPercentage: true
                )
            }
        }
    }

    private func statItem(
        value: Int,
        label: String,
        color: Color,
        isPercentage: Bool = false
    ) -> some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text(isPercentage ? "\(value)%" : "\(value)")
                .font(Theme.Typography.title2)
                .foregroundStyle(color)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Overdue Warning

    private var overdueWarning: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Semantic.overdue)

            Text("\(overdueCount) action\(overdueCount == 1 ? "" : "s") overdue")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Semantic.overdue)

            Spacer()
        }
        .padding(Theme.Spacing.xs)
        .background(Theme.Semantic.overdue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button {
            onAddTap()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Action")
            }
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.KPTA.action)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.KPTA.actionBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add new action")
    }

    // MARK: - Computed Properties

    private var activeCount: Int {
        activeActions.count
    }

    private var overdueCount: Int {
        activeActions.filter { $0.isOverdue }.count
    }

    private var completedTodayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allActions.filter { action in
            guard action.isCompleted, let completedAt = action.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: today)
        }.count
    }

    private var completionPercentage: Int {
        guard allActions.count > 0 else { return 0 }
        let completed = allActions.filter { $0.isCompleted }.count
        return Int((Double(completed) / Double(allActions.count)) * 100)
    }

    private var completionColor: Color {
        switch completionPercentage {
        case 70...100: return Theme.Semantic.completed
        case 40..<70: return Theme.Semantic.warning
        default: return Theme.Semantic.error
        }
    }

    private var accessibilityLabel: String {
        var parts = ["\(activeCount) active actions"]

        if overdueCount > 0 {
            parts.append("\(overdueCount) overdue")
        }

        if completedTodayCount > 0 {
            parts.append("\(completedTodayCount) completed today")
        }

        return "Actions summary: " + parts.joined(separator: ", ")
    }
}

// MARK: - Compact Widget Variant

/// A more compact version of the widget for smaller spaces
struct ActionsSummaryWidgetCompact: View {
    @Query(filter: #Predicate<ActionItem> { !$0.isCompleted })
    private var activeActions: [ActionItem]

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.KPTA.actionBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checklist")
                        .font(.title3)
                        .foregroundStyle(Theme.KPTA.action)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Actions")
                        .font(Theme.Typography.headline)

                    Text(summaryText)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Badge
                if overdueCount > 0 {
                    Text("\(overdueCount)")
                        .font(Theme.Typography.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(Theme.Semantic.overdue)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Theme.Spacing.sm)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Actions: \(summaryText)")
        .accessibilityHint("Double tap to view all actions")
    }

    private var overdueCount: Int {
        activeActions.filter { $0.isOverdue }.count
    }

    private var summaryText: String {
        let count = activeActions.count
        if count == 0 {
            return "No active actions"
        } else if overdueCount > 0 {
            return "\(count) active, \(overdueCount) overdue"
        } else {
            return "\(count) active"
        }
    }
}

// MARK: - Preview

#Preview("Summary Widget") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self, Retrospective.self, KPTAItem.self, HealthSummary.self,
            configurations: config
        )

        // Add sample actions
        let context = container.mainContext

        let action1 = ActionItem(
            text: "Set up Pomodoro timer",
            deadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            priority: .high
        )

        let action2 = ActionItem(
            text: "Review weekly goals",
            deadline: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            priority: .medium
        )

        let action3 = ActionItem(
            text: "Exercise",
            isCompleted: true,
            completedAt: Date(),
            priority: .low
        )

        context.insert(action1)
        context.insert(action2)
        context.insert(action3)

        return ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ActionsSummaryWidget(
                    onTap: {},
                    onAddTap: {}
                )

                ActionsSummaryWidgetCompact(onTap: {})
            }
            .padding()
        }
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
        return ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ActionsSummaryWidget(
                    onTap: {},
                    onAddTap: {}
                )

                ActionsSummaryWidgetCompact(onTap: {})
            }
            .padding()
        }
        .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
