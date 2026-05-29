//
//  ScoreDimensionPicker.swift
//  agile-self
//
//  5-level face selector for a single dimension (1 = worst … 5 = best). Replaces the old
//  1–10 number row to lower the entry barrier: tapping a face is faster than picking a number.
//

import SwiftUI

// MARK: - ScoreDimensionPicker

struct ScoreDimensionPicker: View {
    let dimension: DimensionType
    @Binding var score: Int

    /// Face glyphs for levels 1…5 (sad → happy). Index 0 = level 1.
    private static let faces = ["\u{1F623}", "\u{1F641}", "\u{1F610}", "\u{1F642}", "\u{1F604}"]
    /// Generic quality ladder shown under the row for the selected level.
    private static let levelWords = ["Very low", "Low", "Okay", "Good", "Great"]

    private let range = 1...5
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var selectedWord: String {
        let index = min(max(score, 1), 5) - 1
        return Self.levelWords[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            faceRow
            selectedLabel
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

            // Big selected-value indicator (the 1–5 number).
            Text("\(score)")
                .font(Theme.Typography.scoreMedium)
                .foregroundStyle(Theme.Dimension.color(for: dimension))
                .contentTransition(.numericText())
        }
    }

    // MARK: - Face Row

    private var faceRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(range), id: \.self) { value in
                faceButton(value)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func faceButton(_ value: Int) -> some View {
        let isSelected = value == score
        let color = Theme.Dimension.color(for: dimension)

        return Button {
            updateScore(value)
        } label: {
            Text(Self.faces[value - 1])
                .font(.system(size: 30))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(isSelected ? color.opacity(0.22) : Theme.Colors.backgroundTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(isSelected ? color : .clear, lineWidth: 2)
                )
                .opacity(isSelected ? 1.0 : 0.45)
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .animation(Theme.Animation.scoreSelection, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(dimension.label): \(Self.levelWords[value - 1]), \(value) of 5")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Selected Label

    private var selectedLabel: some View {
        HStack {
            Spacer()
            Text(selectedWord)
                .font(Theme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(Theme.Dimension.color(for: dimension))
                .contentTransition(.numericText())
            Spacer()
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
    @Previewable @State var score = 4

    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        ScoreDimensionPicker(dimension: .energy, score: $score)
            .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("All Dimensions") {
    @Previewable @State var energy = 4
    @Previewable @State var focus = 3
    @Previewable @State var stress = 2
    @Previewable @State var growth = 5

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
