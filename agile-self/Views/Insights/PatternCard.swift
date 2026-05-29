//
//  PatternCard.swift
//  agile-self
//
//  Card displaying an AI-discovered behavioral pattern.
//

import SwiftUI

struct PatternCard: View {
    let title: String
    let description: String
    var icon: String = "lightbulb.fill"

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.Colors.accentStart)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                // Only render the description row when there's text — patterns from Insights
                // carry no description, and an empty Text would leave a dead gap.
                if !description.isEmpty {
                    Text(description)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Theme.Colors.accentStart.opacity(0.4))
                .frame(width: 3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(description.isEmpty ? "Pattern: \(title)" : "Pattern: \(title). \(description)")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.md) {
            PatternCard(
                title: "Focus peaks on run days",
                description: "Your focus scores are 23% higher on days you go for a run."
            )

            PatternCard(
                title: "Sleep affects stress",
                description: "Sleep quality below 7h correlates with higher stress the next day."
            )

            PatternCard(
                title: "Midweek energy dip",
                description: "Wednesday is consistently your lowest energy day.",
                icon: "chart.line.downtrend.xyaxis"
            )
        }
        .padding(Theme.Spacing.md)
    }
}
