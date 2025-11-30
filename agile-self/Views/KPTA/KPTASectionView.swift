//
//  KPTASectionView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI

/// A reusable section view for Keep and Problem categories
struct KPTASectionView: View {
    let category: KPTACategory
    @Binding var items: [DraftKPTAItem]
    let onAdd: () -> Void
    let onRemove: (UUID) -> Void

    @FocusState private var focusedItemId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section Header
            sectionHeader

            // Items List
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    KPTAItemRow(
                        item: binding(for: item.id),
                        index: index + 1,
                        category: category,
                        canRemove: items.count > 1,
                        isFocused: focusedItemId == item.id,
                        onRemove: { onRemove(item.id) },
                        onSubmit: {
                            // Move to next item or add new one
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
        }
        .padding(Theme.Spacing.md)
        .background(Theme.KPTA.backgroundColor(for: category))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(category.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(category.displayName) section")
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

                Text(categoryDescription)
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
                    .accessibilityLabel("\(validItemCount) items")
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
            Label("Add \(category.displayName)", systemImage: "plus.circle.fill")
                .font(Theme.Typography.callout)
                .foregroundStyle(category.color)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Adds a new \(category.displayName.lowercased()) item")
    }

    // MARK: - Helper Properties

    private var categoryDescription: String {
        switch category {
        case .keep:
            return "What went well? What should you continue doing?"
        case .problem:
            return "What obstacles or challenges did you face?"
        case .try:
            return "What new approaches will you experiment with?"
        }
    }

    private var validItemCount: Int {
        items.filter { $0.isValid }.count
    }

    // MARK: - Helper Methods

    private func binding(for id: UUID) -> Binding<DraftKPTAItem> {
        Binding(
            get: {
                items.first { $0.id == id } ?? DraftKPTAItem(category: category)
            },
            set: { newValue in
                if let index = items.firstIndex(where: { $0.id == id }) {
                    items[index] = newValue
                }
            }
        )
    }
}

// MARK: - KPTA Item Row

struct KPTAItemRow: View {
    @Binding var item: DraftKPTAItem
    let index: Int
    let category: KPTACategory
    let canRemove: Bool
    let isFocused: Bool
    let onRemove: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Index Indicator
            Text("\(index)")
                .font(Theme.Typography.caption.weight(.medium))
                .foregroundStyle(category.color.opacity(0.7))
                .frame(width: 20, alignment: .center)
                .accessibilityHidden(true)

            // Text Field
            TextField(
                placeholderText,
                text: $item.text,
                axis: .vertical
            )
            .lineLimit(1...5)
            .textFieldStyle(.plain)
            .font(Theme.Typography.body)
            .submitLabel(.next)
            .onSubmit(onSubmit)
            .accessibilityLabel("\(category.displayName) item \(index)")
            .accessibilityHint(item.text.isEmpty ? "Enter your \(category.displayName.lowercased()) item" : "Edit this item")

            // Remove Button
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove item \(index)")
            }
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(isFocused ? .white.opacity(0.5) : .white.opacity(0.3))
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    private var placeholderText: String {
        switch category {
        case .keep:
            return "What went well..."
        case .problem:
            return "What was challenging..."
        case .try:
            return "What will you try..."
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.md) {
            KPTASectionView(
                category: .keep,
                items: .constant([
                    DraftKPTAItem(text: "Completed all daily standups", category: .keep),
                    DraftKPTAItem(text: "Maintained good sleep schedule", category: .keep),
                    DraftKPTAItem(category: .keep)
                ]),
                onAdd: {},
                onRemove: { _ in }
            )

            KPTASectionView(
                category: .problem,
                items: .constant([
                    DraftKPTAItem(text: "Struggled with focus in afternoons", category: .problem),
                    DraftKPTAItem(category: .problem)
                ]),
                onAdd: {},
                onRemove: { _ in }
            )
        }
        .padding()
    }
}
