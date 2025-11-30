//
//  TrySectionView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI

/// A specialized section view for Try items with action creation capability
struct TrySectionView: View {
    @Binding var items: [DraftTryItem]
    let onAdd: () -> Void
    let onRemove: (UUID) -> Void
    let onToggleAction: (UUID) -> Void

    @FocusState private var focusedItemId: UUID?

    private let category = KPTACategory.try

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section Header
            sectionHeader

            // Items List
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    TryItemRow(
                        item: binding(for: item.id),
                        index: index + 1,
                        canRemove: items.count > 1,
                        isFocused: focusedItemId == item.id,
                        onRemove: { onRemove(item.id) },
                        onToggleAction: { onToggleAction(item.id) },
                        onSubmit: {
                            if index == items.count - 1 {
                                onAdd()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    focusedItemId = items.last?.id
                                }
                            } else {
                                focusedItemId = items[index + 1].id
                            }
                        }
                    )
                    .focused($focusedItemId, equals: item.id)
                }
            }

            // Add Button
            addButton

            // Action Summary
            if actionCount > 0 {
                actionSummary
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.KPTA.tryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Theme.KPTA.try.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Try section with action creation")
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: category.iconName)
                .foregroundStyle(category.color)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(category.color)

                Text("What new approaches will you experiment with?")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Item Count Badge
            if validItemCount > 0 {
                Text("\(validItemCount)")
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(category.color)
                    .clipShape(Capsule())
                    .accessibilityLabel("\(validItemCount) try items")
            }
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            onAdd()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedItemId = items.last?.id
            }
        } label: {
            Label("Add Try", systemImage: "plus.circle.fill")
                .font(Theme.Typography.callout)
                .foregroundStyle(category.color)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Adds a new try item")
    }

    // MARK: - Action Summary

    private var actionSummary: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.square.fill")
                .foregroundStyle(Theme.KPTA.action)

            Text("\(actionCount) action\(actionCount == 1 ? "" : "s") will be created")
                .font(Theme.Typography.callout)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.KPTA.actionBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        .accessibilityLabel("\(actionCount) actions will be created from try items")
    }

    // MARK: - Helper Properties

    private var validItemCount: Int {
        items.filter { $0.isValid }.count
    }

    private var actionCount: Int {
        items.filter { $0.hasValidAction }.count
    }

    // MARK: - Helper Methods

    private func binding(for id: UUID) -> Binding<DraftTryItem> {
        Binding(
            get: {
                items.first { $0.id == id } ?? DraftTryItem()
            },
            set: { newValue in
                if let index = items.firstIndex(where: { $0.id == id }) {
                    items[index] = newValue
                }
            }
        )
    }
}

// MARK: - Try Item Row

struct TryItemRow: View {
    @Binding var item: DraftTryItem
    let index: Int
    let canRemove: Bool
    let isFocused: Bool
    let onRemove: () -> Void
    let onToggleAction: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Main Try Item
            mainItemRow

            // Action Creation Section
            if item.isValid {
                actionSection
            }
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(isFocused ? .white.opacity(0.5) : .white.opacity(0.3))
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: item.createAction)
    }

    // MARK: - Main Item Row

    private var mainItemRow: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Index Indicator
            Text("\(index)")
                .font(Theme.Typography.caption.weight(.medium))
                .foregroundStyle(Theme.KPTA.try.opacity(0.7))
                .frame(width: 20, alignment: .center)
                .accessibilityHidden(true)

            // Text Field
            TextField(
                "What will you try...",
                text: $item.text,
                axis: .vertical
            )
            .lineLimit(1...5)
            .textFieldStyle(.plain)
            .font(Theme.Typography.body)
            .submitLabel(.next)
            .onSubmit(onSubmit)
            .accessibilityLabel("Try item \(index)")
            .accessibilityHint(item.text.isEmpty ? "Enter what you will try" : "Edit this item")

            // Remove Button
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove try item \(index)")
            }
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Create Action Toggle
            Button(action: onToggleAction) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: item.createAction ? "checkmark.square.fill" : "square")
                        .foregroundStyle(Theme.KPTA.action)
                        .font(.body)
                        .contentTransition(.symbolEffect(.replace))

                    Text("Create Action Item")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(item.createAction ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.createAction ? "Action item enabled" : "Create action item")
            .accessibilityHint(item.createAction ? "Double tap to disable action creation" : "Double tap to create an action from this try item")

            // Action Details (when enabled)
            if item.createAction {
                actionDetailsView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(.leading, 28) // Align with text field
    }

    // MARK: - Action Details View

    private var actionDetailsView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Action Text Field
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "arrow.turn.down.right")
                    .foregroundStyle(Theme.KPTA.action.opacity(0.7))
                    .font(.caption)
                    .accessibilityHidden(true)

                TextField(
                    "Action: What specifically will you do?",
                    text: $item.actionText,
                    axis: .vertical
                )
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .font(Theme.Typography.callout)
                .padding(Theme.Spacing.xs)
                .background(Theme.KPTA.actionBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                .accessibilityLabel("Action text")
                .accessibilityHint("Enter a specific action you will take")
            }

            // Deadline Toggle and Picker
            deadlineSection
        }
    }

    // MARK: - Deadline Section

    private var deadlineSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    item.showDeadlinePicker.toggle()
                    if item.showDeadlinePicker && item.actionDeadline == nil {
                        // Default to one week from now
                        item.actionDeadline = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
                    }
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: item.actionDeadline != nil ? "calendar.badge.clock" : "calendar")
                        .foregroundStyle(Theme.KPTA.action.opacity(0.7))
                        .font(.caption)

                    if let deadline = item.actionDeadline {
                        Text("Due: \(formattedDate(deadline))")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Add deadline (optional)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    if item.actionDeadline != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                item.actionDeadline = nil
                                item.showDeadlinePicker = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove deadline")
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.actionDeadline != nil ? "Deadline: \(formattedDate(item.actionDeadline!))" : "Add deadline")

            if item.showDeadlinePicker {
                DatePicker(
                    "Deadline",
                    selection: Binding(
                        get: { item.actionDeadline ?? Date() },
                        set: { item.actionDeadline = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Helper Methods

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        TrySectionView(
            items: .constant([
                DraftTryItem(
                    text: "Use Pomodoro technique for focused work",
                    createAction: true,
                    actionText: "Set up Pomodoro timer app and use it daily",
                    actionDeadline: Calendar.current.date(byAdding: .day, value: 3, to: Date())
                ),
                DraftTryItem(
                    text: "Morning journaling before checking phone",
                    createAction: false
                ),
                DraftTryItem()
            ]),
            onAdd: {},
            onRemove: { _ in },
            onToggleAction: { _ in }
        )
        .padding()
    }
}
