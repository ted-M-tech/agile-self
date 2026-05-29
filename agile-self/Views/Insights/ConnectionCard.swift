//
//  ConnectionCard.swift
//  agile-self
//
//  Displays one AI-narrated "connection" between a health metric and how the user feels, with a
//  subtle supporting coefficient/arrow. The sentence carries the deterministic numbers; this is
//  the honest, plain-language replacement for the old bare-coefficient correlation list.
//

import SwiftUI

struct ConnectionCard: View {
    /// The AI-narrated connection sentence (numbers are deterministic, never invented).
    let sentence: String
    /// The underlying correlation, used only for the subtle supporting arrow + magnitude tint.
    let correlation: Correlation?

    private var isPositive: Bool {
        (correlation?.coefficient ?? 0) >= 0
    }

    private var accentColor: Color {
        isPositive ? Theme.Colors.success : Theme.Colors.warning
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(accentColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(sentence)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                if let correlation {
                    Text("\(correlation.factor1) · \(correlation.factor2) · strength \(String(format: "%.2f", abs(correlation.coefficient)))")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .colorBorderCard(accentColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sentence)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: Theme.Spacing.md) {
            ConnectionCard(
                sentence: "On days with more sleep (around 7h 40m), your Focus tends to run about +1.2 higher.",
                correlation: Correlation(
                    factor1: "Sleep",
                    factor2: "Focus",
                    coefficient: 0.72,
                    description: "Sleep↑ = Focus↑"
                )
            )
            ConnectionCard(
                sentence: "More screen time tends to line up with lower Calm days.",
                correlation: Correlation(
                    factor1: "Screen Time",
                    factor2: "Calm",
                    coefficient: -0.54,
                    description: "Screen Time↑ = Calm↓"
                )
            )
        }
        .padding(Theme.Spacing.md)
    }
}
