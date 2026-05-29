//
//  HealthMetricCard.swift
//  agile-self
//
//  Compact health metric card for horizontal scroll display.
//

import SwiftUI

struct HealthMetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(Theme.Typography.scoreSmall)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 96)
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#Preview {
    let health = MockData.todayHealth

    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.sm) {
                HealthMetricCard(
                    icon: "bed.double.fill",
                    value: health.formattedSleep ?? "--",
                    label: "Sleep",
                    color: .indigo
                )
                HealthMetricCard(
                    icon: "figure.walk",
                    value: health.formattedSteps ?? "--",
                    label: "Steps",
                    color: .orange
                )
                HealthMetricCard(
                    icon: "heart.fill",
                    value: health.formattedHeartRate ?? "--",
                    label: "Heart Rate",
                    color: .red
                )
                HealthMetricCard(
                    icon: "iphone",
                    value: health.formattedScreenTime ?? "--",
                    label: "Screen Time",
                    color: .cyan
                )
                HealthMetricCard(
                    icon: "figure.run",
                    value: health.formattedRunDistance ?? "--",
                    label: "Running",
                    color: .green
                )
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}
