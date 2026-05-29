//
//  WatchCheckInView.swift
//  agile-self Watch App
//
//  4-step Digital Crown check-in flow for Watch.
//

import SwiftUI

struct WatchCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    var connectivity: WatchConnectivityManager

    @State private var currentStep = 0
    @State private var scores: [Int] = [3, 3, 3, 3]
    @State private var showConfirmation = false
    @State private var showSuccess = false

    private let dimensions = WatchDimensionType.allCases

    var body: some View {
        Group {
            if showSuccess {
                successView
            } else if showConfirmation {
                confirmationView
            } else {
                dimensionPicker
            }
        }
        .background(WatchTheme.Colors.backgroundPrimary)
    }

    // MARK: - Dimension Picker

    private var dimensionPicker: some View {
        let dimension = dimensions[currentStep]
        let color = WatchTheme.Dimension.color(for: dimension)

        return VStack(spacing: 4) {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? color : WatchTheme.Colors.textTertiary)
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            // Icon + Label
            Image(systemName: dimension.icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(dimension.label)
                .font(.headline)
                .foregroundStyle(WatchTheme.Colors.textPrimary)

            // Score display
            Text("\(scores[currentStep])")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .focusable()
                .digitalCrownRotation(
                    detent: $scores[currentStep],
                    from: 1,
                    through: 5,
                    by: 1,
                    sensitivity: .low,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )

            Spacer()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button {
                        withAnimation { currentStep -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(WatchTheme.Colors.textSecondary)
                }

                Spacer()

                Button {
                    withAnimation {
                        if currentStep < 3 {
                            currentStep += 1
                        } else {
                            showConfirmation = true
                        }
                    }
                } label: {
                    Text(currentStep < 3 ? "Next" : "Review")
                        .font(.footnote.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Confirmation

    private var confirmationView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(String(format: "%.1f", compositeScore))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        WatchTheme.Colors.accentGradient
                    )

                Text("Composite")
                    .font(.caption2)
                    .foregroundStyle(WatchTheme.Colors.textSecondary)

                ForEach(Array(dimensions.enumerated()), id: \.element.id) { index, dim in
                    HStack {
                        Image(systemName: dim.icon)
                            .font(.caption2)
                            .foregroundStyle(WatchTheme.Dimension.color(for: dim))
                        Text(dim.label)
                            .font(.caption2)
                            .foregroundStyle(WatchTheme.Colors.textSecondary)
                        Spacer()
                        Text("\(scores[index])")
                            .font(.caption.bold())
                            .foregroundStyle(WatchTheme.Colors.textPrimary)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        withAnimation { showConfirmation = false }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(WatchTheme.Colors.textSecondary)

                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                WatchTheme.Colors.accentGradient,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(WatchTheme.Colors.success)

            Text("Saved!")
                .font(.headline)
                .foregroundStyle(WatchTheme.Colors.textPrimary)

            Text(String(format: "%.1f", compositeScore))
                .font(.title3.bold())
                .foregroundStyle(
                    WatchTheme.Colors.accentGradient
                )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private var compositeScore: Double {
        // scores[2] is the Calm axis (high = calm/good).
        computeCompositeScore(energy: scores[0], focus: scores[1], calm: scores[2], growth: scores[3])
    }

    private func save() {
        connectivity.sendCheckIn(
            energy: scores[0],
            focus: scores[1],
            calm: scores[2],
            growth: scores[3]
        )
        withAnimation { showSuccess = true }
    }
}

#Preview {
    WatchCheckInView(connectivity: WatchConnectivityManager())
}
