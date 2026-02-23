//
//  ActionRow.swift
//  agile-self
//
//  Reusable action item row with checkbox, priority pill, and deadline badge.
//

import SwiftUI

struct ActionRow: View {
    let action: ActionItemV2
    var onToggle: (() -> Void)?

    private var deadlineText: String? {
        guard let days = action.daysUntilDeadline else { return nil }
        if days < 0 {
            return "\(abs(days))d overdue"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days)d left"
        }
    }

    private var deadlineColor: Color {
        guard let days = action.daysUntilDeadline else { return Theme.Colors.textTertiary }
        if days < 0 { return Theme.Colors.warning }
        if days <= 2 { return Theme.Dimension.energy }
        return Theme.Colors.textSecondary
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Checkbox
            checkboxButton

            // Text content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(action.text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(action.isCompleted ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    .strikethrough(action.isCompleted, color: Theme.Colors.textTertiary)
                    .lineLimit(2)

                // Metadata row
                if !action.isCompleted {
                    HStack(spacing: Theme.Spacing.sm) {
                        // Priority pill
                        Text(action.priority.displayName)
                            .pillStyle(color: action.priority.color)

                        // Source badge
                        if action.source == .aiSuggested {
                            Label("AI", systemImage: "sparkles")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.accentStart)
                        }

                        Spacer()

                        // Deadline
                        if let deadline = deadlineText {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(deadline)
                                    .font(Theme.Typography.caption)
                            }
                            .foregroundStyle(deadlineColor)
                        }
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Checkbox

    private var checkboxButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onToggle?()
        } label: {
            Image(systemName: action.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(action.isCompleted ? Theme.Colors.success : Theme.Colors.textTertiary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.isCompleted ? "Completed" : "Mark as complete")
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = [action.text]
        parts.append("Priority: \(action.priority.displayName)")
        if action.isCompleted {
            parts.append("Completed")
        }
        if let deadline = deadlineText {
            parts.append(deadline)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        VStack(spacing: 0) {
            ForEach(MockData.actionItems, id: \.id) { action in
                ActionRow(action: action) {
                    action.toggleCompletion()
                }
                Divider()
                    .overlay(Theme.Colors.divider)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    .preferredColorScheme(.dark)
}
