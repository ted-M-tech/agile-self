//
//  KPTAInputStepView.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI

/// A clean, focused input step for Keep, Problem, or Try items
struct KPTAInputStepView: View {
    let step: KPTAWizardStep
    @Binding var items: [DraftKPTAItem]
    let onAddItem: () -> Void
    let onRemoveItem: (UUID) -> Void

    @FocusState private var focusedItemId: UUID?

    private var placeholder: String {
        switch step {
        case .keep: return "Something that went well..."
        case .problem: return "A challenge you faced..."
        case .tryStep: return "Something you'll try..."
        default: return "Add an item..."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            stepHeader
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.lg)

            // Items list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach($items) { $item in
                        KPTAItemInputRow(
                            text: $item.text,
                            placeholder: placeholder,
                            color: step.color,
                            onSubmit: {
                                handleSubmit(for: item)
                            },
                            onDelete: items.count > 1 ? { onRemoveItem(item.id) } : nil
                        )
                        .focused($focusedItemId, equals: item.id)
                    }

                    // Add button
                    KPTAAddItemRow(
                        placeholder: "Add another",
                        color: step.color,
                        onTap: {
                            onAddItem()
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(100))
                                focusedItemId = items.last?.id
                            }
                        }
                    )
                }
                .padding(.horizontal, Theme.Spacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            // Focus first empty item or last item
            if let firstEmpty = items.first(where: { $0.text.isEmpty }) {
                focusedItemId = firstEmpty.id
            } else {
                focusedItemId = items.last?.id
            }
        }
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Large muted icon
            Image(systemName: step.iconName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(step.color.opacity(0.2))

            // Title
            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            // Subtitle
            Text(step.subtitle)
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Actions

    private func handleSubmit(for item: DraftKPTAItem) {
        if let currentIndex = items.firstIndex(where: { $0.id == item.id }) {
            if currentIndex == items.count - 1 {
                // Last item - add new one
                if !item.text.isEmpty {
                    onAddItem()
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        focusedItemId = items.last?.id
                    }
                }
            } else {
                // Move to next item
                focusedItemId = items[currentIndex + 1].id
            }
        }
    }
}

/// Specialized version for Try items (which have different structure)
struct KPTATryInputStepView: View {
    let step: KPTAWizardStep
    @Binding var items: [DraftTryItem]
    let onAddItem: () -> Void
    let onRemoveItem: (UUID) -> Void

    @FocusState private var focusedItemId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            stepHeader
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.lg)

            // Items list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach($items) { $item in
                        TryItemInputRow(
                            item: $item,
                            color: step.color,
                            onSubmit: {
                                handleSubmit(for: item)
                            },
                            onDelete: items.count > 1 ? { onRemoveItem(item.id) } : nil
                        )
                        .focused($focusedItemId, equals: item.id)
                    }

                    // Add button
                    KPTAAddItemRow(
                        placeholder: "Add another",
                        color: step.color,
                        onTap: {
                            onAddItem()
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(100))
                                focusedItemId = items.last?.id
                            }
                        }
                    )
                }
                .padding(.horizontal, Theme.Spacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            if let firstEmpty = items.first(where: { $0.text.isEmpty }) {
                focusedItemId = firstEmpty.id
            } else {
                focusedItemId = items.last?.id
            }
        }
    }

    private var stepHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: step.iconName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(step.color.opacity(0.2))

            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(step.subtitle)
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func handleSubmit(for item: DraftTryItem) {
        if let currentIndex = items.firstIndex(where: { $0.id == item.id }) {
            if currentIndex == items.count - 1 {
                if !item.text.isEmpty {
                    onAddItem()
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        focusedItemId = items.last?.id
                    }
                }
            } else {
                focusedItemId = items[currentIndex + 1].id
            }
        }
    }
}

/// Input row for Try items
private struct TryItemInputRow: View {
    @Binding var item: DraftTryItem
    let color: Color
    let onSubmit: () -> Void
    let onDelete: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(item.text.isEmpty ? Color(.systemGray4) : color)
                .frame(width: 8, height: 8)

            TextField("Something you'll try...", text: $item.text, axis: .vertical)
                .lineLimit(1...4)
                .font(Theme.Typography.body)
                .focused($isFocused)
                .submitLabel(.next)
                .onSubmit(onSubmit)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(isFocused ? Color(.systemGray6) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Keep Step") {
    KPTAInputStepView(
        step: .keep,
        items: .constant([
            DraftKPTAItem(text: "Completed all standups", category: .keep),
            DraftKPTAItem(text: "", category: .keep)
        ]),
        onAddItem: {},
        onRemoveItem: { _ in }
    )
}

#Preview("Try Step") {
    KPTATryInputStepView(
        step: .tryStep,
        items: .constant([
            DraftTryItem(text: "Use Pomodoro technique"),
            DraftTryItem()
        ]),
        onAddItem: {},
        onRemoveItem: { _ in }
    )
}
