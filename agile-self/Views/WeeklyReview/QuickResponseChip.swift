//
//  QuickResponseChip.swift
//  agile-self
//
//  Horizontal scroll of quick response suggestion chips for the AI conversation.
//

import SwiftUI

// MARK: - QuickResponseChip

struct QuickResponseChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.backgroundTertiary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.accentStart.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: text)
        .accessibilityLabel("Quick response: \(text)")
        .accessibilityHint("Double tap to send this response")
    }
}

// MARK: - QuickResponseChipRow

struct QuickResponseChipRow: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(suggestions, id: \.self) { suggestion in
                    QuickResponseChip(text: suggestion) {
                        onSelect(suggestion)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.lg) {
            QuickResponseChipRow(
                suggestions: [
                    "I felt more energized",
                    "Work was stressful",
                    "I exercised regularly",
                    "Better sleep helped",
                ],
                onSelect: { _ in }
            )

            QuickResponseChip(text: "Yes, definitely") {}
        }
    }
    .preferredColorScheme(.dark)
}
