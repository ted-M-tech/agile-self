//
//  DimensionCard.swift
//  agile-self
//
//  Dimension score card with animated circular progress ring.
//

import SwiftUI

struct DimensionCard: View {
    let dimension: DimensionType
    let score: Int

    @State private var animateRing = false

    private var progress: Double {
        Double(score) / 10.0
    }

    private var dimensionColor: Color {
        Theme.Dimension.color(for: dimension)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Icon + Label
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: dimension.icon)
                    .font(.footnote)
                    .foregroundStyle(dimensionColor)

                Text(dimension.label.uppercased())
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.8)

                Spacer()
            }

            // Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        dimensionColor.opacity(0.15),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )

                // Foreground ring
                Circle()
                    .trim(from: 0, to: animateRing ? progress : 0)
                    .stroke(
                        dimensionColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(Theme.Typography.scoreMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("/10")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .frame(width: 72, height: 72)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .onAppear {
            withAnimation(Theme.Animation.ringFill) {
                animateRing = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dimension.label) score: \(score) out of 10")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.md
        ) {
            ForEach(DimensionType.allCases) { dim in
                DimensionCard(
                    dimension: dim,
                    score: MockData.todayCheckIn.score(for: dim)
                )
            }
        }
        .padding(Theme.Spacing.md)
    }
}
