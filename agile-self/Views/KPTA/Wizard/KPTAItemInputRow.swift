//
//  KPTAItemInputRow.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI

/// A minimal, clean input row for KPTA items
struct KPTAItemInputRow: View {
    @Binding var text: String
    let placeholder: String
    let color: Color
    let onSubmit: () -> Void
    let onDelete: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Bullet point
            Circle()
                .fill(text.isEmpty ? Color(.systemGray4) : color)
                .frame(width: 8, height: 8)

            // Text input
            TextField(placeholder, text: $text, axis: .vertical)
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
                Button(role: .destructive) {
                    withAnimation(Theme.Animation.smooth) {
                        onDelete()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text.isEmpty ? placeholder : text)
        .accessibilityHint("Double tap to edit")
    }

    func focused(_ focused: Bool) -> some View {
        var copy = self
        copy._isFocused = FocusState()
        return copy
    }
}

/// Row for adding new items
struct KPTAAddItemRow: View {
    let placeholder: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                    .foregroundStyle(color.opacity(0.6))

                Text(placeholder)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add new item")
        .accessibilityHint("Double tap to add a new entry")
    }
}

// MARK: - Preview

#Preview {
    List {
        Section {
            KPTAItemInputRow(
                text: .constant("Completed daily standups"),
                placeholder: "What went well...",
                color: Theme.KPTA.keep,
                onSubmit: {},
                onDelete: {}
            )

            KPTAItemInputRow(
                text: .constant(""),
                placeholder: "What went well...",
                color: Theme.KPTA.keep,
                onSubmit: {},
                onDelete: nil
            )

            KPTAAddItemRow(
                placeholder: "Add another",
                color: Theme.KPTA.keep,
                onTap: {}
            )
        }
    }
}
