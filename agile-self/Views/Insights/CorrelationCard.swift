//
//  CorrelationCard.swift
//  agile-self
//
//  Displays a single health-score correlation with a coefficient bar.
//

import SwiftUI

struct CorrelationCard: View {
    let correlation: Correlation

    private var isPositive: Bool {
        correlation.coefficient >= 0
    }

    private var barColor: Color {
        isPositive ? Theme.Colors.success : Theme.Colors.warning
    }

    /// Normalized bar width (0...1) from the coefficient magnitude.
    private var barFraction: CGFloat {
        CGFloat(min(abs(correlation.coefficient), 1.0))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Factor labels
            HStack(spacing: Theme.Spacing.xs) {
                Text(correlation.factor1)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Text(correlation.factor2)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Text(String(format: "%+.2f", correlation.coefficient))
                    .font(Theme.Typography.scoreSmall)
                    .foregroundStyle(barColor)
            }

            // Coefficient bar
            coefficientBar

            // Description
            Text(correlation.description)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .colorBorderCard(barColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(correlation.factor1) to \(correlation.factor2), correlation \(String(format: "%.2f", correlation.coefficient)). \(correlation.description)"
        )
    }

    // MARK: - Coefficient Bar

    private var coefficientBar: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let midPoint = totalWidth / 2

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.Colors.backgroundTertiary)
                    .frame(height: 6)

                // Center line
                Rectangle()
                    .fill(Theme.Colors.textTertiary.opacity(0.5))
                    .frame(width: 1, height: 10)
                    .position(x: midPoint, y: 5)

                // Fill bar from center
                if isPositive {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: barFraction * (totalWidth / 2), height: 6)
                        .offset(x: midPoint)
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: barFraction * (totalWidth / 2), height: 6)
                        .offset(x: midPoint - barFraction * (totalWidth / 2))
                }
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.md) {
            CorrelationCard(
                correlation: Correlation(
                    factor1: "Sleep",
                    factor2: "Focus",
                    coefficient: 0.72,
                    description: "Sleep\u{2191} = Focus\u{2191}"
                )
            )

            // Calm is high = good, so more screen time lowering calm is a NEGATIVE
            // coefficient → the card renders it in the "bad" warning color with a
            // down arrow. Verifies the sign-driven direction reads correctly.
            CorrelationCard(
                correlation: Correlation(
                    factor1: "Screen Time",
                    factor2: "Calm",
                    coefficient: -0.54,
                    description: "Screen Time\u{2191} = Calm\u{2193}"
                )
            )
        }
        .padding(Theme.Spacing.md)
    }
}
