//
//  ScoreDimensionPicker.swift
//  agile-self
//
//  Horizontal 1-10 score picker for a single dimension.
//

import SwiftUI

// MARK: - ScoreDimensionPicker

struct ScoreDimensionPicker: View {
    let dimension: DimensionType
    @Binding var score: Int

    private let range = 1...10
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            scoreRow
            scaleLabels
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(Theme.Dimension.background(for: dimension))
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(Theme.Colors.backgroundSecondary)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: dimension.icon)
                .font(.title3)
                .foregroundStyle(Theme.Dimension.color(for: dimension))

            VStack(alignment: .leading, spacing: 2) {
                Text(dimension.label)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(dimension.question)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Text("\(score)")
                .font(Theme.Typography.scoreMedium)
                .foregroundStyle(Theme.Dimension.color(for: dimension))
                .contentTransition(.numericText())
        }
    }

    // MARK: - Score Row

    private var scoreRow: some View {
        GeometryReader { geometry in
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(range), id: \.self) { value in
                    scoreButton(value)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { gesture in
                        let totalWidth = geometry.size.width
                        let x = min(max(gesture.location.x, 0), totalWidth)
                        let fraction = x / totalWidth
                        let newValue = Int(round(fraction * 9)) + 1
                        let clamped = min(max(newValue, 1), 10)
                        if clamped != score {
                            updateScore(clamped)
                        }
                    }
            )
        }
        .frame(height: 42)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dimension.label) score")
        .accessibilityValue("\(score) out of 10")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if score < 10 { updateScore(score + 1) }
            case .decrement:
                if score > 1 { updateScore(score - 1) }
            @unknown default:
                break
            }
        }
    }

    private func scoreButton(_ value: Int) -> some View {
        let isSelected = value == score

        return Text("\(value)")
            .font(isSelected ? Theme.Typography.headline : Theme.Typography.callout)
            .foregroundStyle(isSelected ? .white : Theme.Colors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(isSelected
                          ? Theme.Dimension.color(for: dimension)
                          : Theme.Colors.backgroundTertiary)
            )
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(Theme.Animation.scoreSelection, value: isSelected)
            .onTapGesture {
                updateScore(value)
            }
    }

    // MARK: - Scale Labels

    private var scaleLabels: some View {
        HStack {
            Text(dimension.isInverted ? "Calm" : "Low")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            Spacer()

            Text(scoreDescriptor)
                .font(Theme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(Theme.Dimension.color(for: dimension))
                .contentTransition(.numericText())

            Spacer()

            Text(dimension.isInverted ? "Very High" : "Great")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    private var scoreDescriptor: String {
        if dimension.isInverted {
            // Stress: 1-3 = calm, 4-5 = mild, 6-7 = stressed, 8-10 = very stressed
            switch score {
            case 1...3: return "Calm"
            case 4...5: return "Mild"
            case 6...7: return "Stressed"
            default: return "Very Stressed"
            }
        } else {
            switch score {
            case 1...3: return "Low"
            case 4...5: return "Moderate"
            case 6...7: return "Good"
            default: return "Great"
            }
        }
    }

    // MARK: - Actions

    private func updateScore(_ value: Int) {
        guard value != score else { return }
        feedbackGenerator.impactOccurred()
        withAnimation(Theme.Animation.scoreSelection) {
            score = value
        }
    }
}

// MARK: - Preview

#Preview("Energy") {
    @Previewable @State var score = 7

    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        ScoreDimensionPicker(dimension: .energy, score: $score)
            .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("All Dimensions") {
    @Previewable @State var energy = 8
    @Previewable @State var focus = 6
    @Previewable @State var stress = 3
    @Previewable @State var growth = 7

    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ScoreDimensionPicker(dimension: .energy, score: $energy)
                ScoreDimensionPicker(dimension: .focus, score: $focus)
                ScoreDimensionPicker(dimension: .stress, score: $stress)
                ScoreDimensionPicker(dimension: .growth, score: $growth)
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
