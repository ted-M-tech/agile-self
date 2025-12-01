//
//  ActionRowView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// A row view displaying a single action item with completion toggle, priority, and due date
struct ActionRowView: View {
    @Bindable var action: ActionItem
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                // Completion Checkbox
                completionCheckbox

                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    // Action Text
                    actionText

                    // Badges Row
                    badgesRow
                }

                Spacer(minLength: 0)

                // Priority Indicator
                priorityIndicator
            }
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(action.isCompleted ? .isSelected : [])
    }

    // MARK: - Completion Checkbox

    private var completionCheckbox: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggleComplete()
            }
        } label: {
            Image(systemName: action.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(action.isCompleted ? Theme.Semantic.completed : .secondary)
                .symbolEffect(.bounce, value: action.isCompleted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle completion")
    }

    // MARK: - Action Text

    private var actionText: some View {
        Text(action.text)
            .font(Theme.Typography.body)
            .foregroundStyle(action.isCompleted ? .secondary : .primary)
            .strikethrough(action.isCompleted, color: .secondary)
            .lineLimit(3)
            .animation(.easeInOut(duration: 0.2), value: action.isCompleted)
    }

    // MARK: - Badges Row

    @ViewBuilder
    private var badgesRow: some View {
        if hasBadges {
            HStack(spacing: Theme.Spacing.xs) {
                // Overdue Badge
                if action.isOverdue {
                    overdueBadge
                }

                // Due Date Badge
                if let deadline = action.deadline, !action.isOverdue {
                    dueDateBadge(deadline)
                }

                // From Try Badge
                if action.fromTryItem {
                    fromTryBadge
                }
            }
        }
    }

    private var hasBadges: Bool {
        action.isOverdue || action.deadline != nil || action.fromTryItem
    }

    private var overdueBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.circle.fill")
            Text("Overdue")
        }
        .font(Theme.Typography.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 2)
        .background(Theme.Semantic.overdue)
        .clipShape(Capsule())
    }

    private func dueDateBadge(_ date: Date) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "calendar")
            Text(formattedDeadline(date))
        }
        .font(Theme.Typography.caption)
        .foregroundStyle(deadlineColor(date))
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 2)
        .background(deadlineColor(date).opacity(0.15))
        .clipShape(Capsule())
    }

    private var fromTryBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "arrow.right.circle")
            Text("From Try")
        }
        .font(Theme.Typography.caption)
        .foregroundStyle(Theme.KPTA.try)
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 2)
        .background(Theme.KPTA.tryBackground)
        .clipShape(Capsule())
    }

    // MARK: - Priority Indicator

    private var priorityIndicator: some View {
        Image(systemName: action.priority.iconName)
            .font(.body)
            .foregroundStyle(action.priority.color)
            .accessibilityLabel("\(action.priority.displayName) priority")
    }

    // MARK: - Helper Methods

    private func formattedDeadline(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if let days = action.daysUntilDeadline, days <= 7, days > 0 {
            return "\(days)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private func deadlineColor(_ date: Date) -> Color {
        guard let days = action.daysUntilDeadline else { return .secondary }

        if days <= 0 {
            return Theme.Semantic.overdue
        } else if days <= 2 {
            return Theme.Semantic.warning
        } else {
            return .secondary
        }
    }

    private var accessibilityLabel: String {
        var parts: [String] = []

        parts.append(action.text)

        if action.isCompleted {
            parts.append("Completed")
        }

        parts.append("\(action.priority.displayName) priority")

        if action.isOverdue {
            parts.append("Overdue")
        } else if let deadline = action.deadline {
            parts.append("Due \(formattedDeadline(deadline))")
        }

        if action.fromTryItem {
            parts.append("Created from a Try item")
        }

        return parts.joined(separator: ". ")
    }
}

// MARK: - Preview

#Preview("Active Action") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self,
            configurations: config
        )

        let action = ActionItem(
            text: "Set up Pomodoro timer and use daily for focused work sessions",
            deadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            fromTryItem: true,
            priority: .high
        )

        return List {
            ActionRowView(
                action: action,
                onToggleComplete: { action.isCompleted.toggle() },
                onTap: {}
            )
        }
        .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}

#Preview("Completed Action") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self,
            configurations: config
        )

        let action = ActionItem(
            text: "Review weekly goals every Monday morning",
            isCompleted: true,
            deadline: Date(),
            completedAt: Date(),
            priority: .medium
        )

        return List {
            ActionRowView(
                action: action,
                onToggleComplete: { action.isCompleted.toggle() },
                onTap: {}
            )
        }
        .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}

#Preview("Overdue Action") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self,
            configurations: config
        )

        let action = ActionItem(
            text: "Complete project documentation",
            deadline: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            priority: .high
        )

        return List {
            ActionRowView(
                action: action,
                onToggleComplete: { action.isCompleted.toggle() },
                onTap: {}
            )
        }
        .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
