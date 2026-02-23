//
//  AIInsightCard.swift
//  agile-self
//
//  Card displaying AI-generated daily insight.
//

import SwiftUI

struct AIInsightCard: View {
    let insight: String?

    var body: some View {
        if let insight {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.accentStart)

                    Text("AI Insight")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text(insight)
                    .font(Theme.Typography.body)
                    .italic()
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Theme.Colors.accentStart.opacity(0.3), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("AI Insight: \(insight)")
        }
    }
}

// MARK: - Preview

#Preview("With Insight") {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        AIInsightCard(
            insight: MockData.todayCheckIn.dailyInsight
        )
        .padding(Theme.Spacing.md)
    }
}

#Preview("No Insight") {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        AIInsightCard(insight: nil)
            .padding(Theme.Spacing.md)
    }
}
