//
//  CheckInConfirmationView.swift
//  agile-self
//
//  Post-save confirmation overlay with animated checkmark and score summary.
//

import SwiftUI

// MARK: - CheckInConfirmationView

struct CheckInConfirmationView: View {
    let energyScore: Int
    let focusScore: Int
    let stressScore: Int
    let growthScore: Int
    let elapsedSeconds: Int
    let previousComposite: Double?
    var insight: String?
    let onDismiss: () -> Void

    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var particles: [Particle] = []
    @State private var autoDismissTask: Task<Void, Never>?

    private var compositeScore: Double {
        let invertedStress = 11 - stressScore
        return Double(energyScore + focusScore + invertedStress + growthScore) / 4.0
    }

    private var delta: Double? {
        guard let previous = previousComposite else { return nil }
        return compositeScore - previous
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Theme.Colors.backgroundPrimary
                .opacity(0.92)
                .ignoresSafeArea()
                .onTapGesture {
                    autoDismissTask?.cancel()
                    onDismiss()
                }

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                // Checkmark with particles
                ZStack {
                    particleBurst
                    checkmarkCircle
                }
                .frame(height: 120)

                // Logged time
                Text("Logged in \(elapsedSeconds)s")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                // Composite score
                compositeScoreDisplay
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                // Dimension badges
                dimensionBadgeRow
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                // AI insight
                insightCard
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .onAppear {
            startAnimations()
            scheduleAutoDismiss()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    // MARK: - Checkmark Circle

    private var checkmarkCircle: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.success.opacity(0.15))
                .frame(width: 96, height: 96)
                .scaleEffect(showCheckmark ? 1 : 0.5)
                .opacity(showCheckmark ? 1 : 0)

            Circle()
                .stroke(Theme.Colors.success, lineWidth: 3)
                .frame(width: 96, height: 96)
                .scaleEffect(showCheckmark ? 1 : 0.5)
                .opacity(showCheckmark ? 1 : 0)

            CheckmarkShape()
                .trim(from: 0, to: showCheckmark ? 1 : 0)
                .stroke(
                    Theme.Colors.success,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 40, height: 40)
        }
    }

    // MARK: - Particle Burst

    private var particleBurst: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
    }

    // MARK: - Composite Score

    private var compositeScoreDisplay: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Text(String(format: "%.1f", compositeScore))
                    .font(Theme.Typography.scoreLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                if let delta, abs(delta) >= 0.1 {
                    HStack(spacing: 2) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(String(format: "%+.1f", delta))
                            .font(Theme.Typography.scoreSmall)
                    }
                    .foregroundStyle(delta >= 0 ? Theme.Colors.success : Theme.Colors.warning)
                }
            }

            Text("Composite Score")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Dimension Badges

    private var dimensionBadgeRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(DimensionType.allCases) { dimension in
                let value = scoreFor(dimension)
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: dimension.icon)
                        .font(.caption)
                        .foregroundStyle(Theme.Dimension.color(for: dimension))

                    Text("\(value)")
                        .font(Theme.Typography.scoreSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Dimension.background(for: dimension))
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
            }
        }
    }

    // MARK: - AI Insight Card

    private var insightCard: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(Theme.Colors.accentStart)

            Text(insight ?? "Check-in saved successfully!")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Helpers

    private func scoreFor(_ dimension: DimensionType) -> Int {
        switch dimension {
        case .energy: return energyScore
        case .focus: return focusScore
        case .stress: return stressScore
        case .growth: return growthScore
        }
    }

    private func startAnimations() {
        // Checkmark draw
        withAnimation(Theme.Animation.checkmarkDraw.delay(0.1)) {
            showCheckmark = true
        }

        // Content fade in
        withAnimation(Theme.Animation.smooth.delay(0.5)) {
            showContent = true
        }

        // Particle burst
        spawnParticles()
    }

    private func spawnParticles() {
        let colors: [Color] = [
            Theme.Dimension.energy,
            Theme.Dimension.focus,
            Theme.Dimension.stress,
            Theme.Dimension.growth,
            Theme.Colors.success,
            Theme.Colors.accentStart,
        ]

        for i in 0..<18 {
            let angle = Double(i) * (360.0 / 18.0) * .pi / 180.0
            let distance: CGFloat = CGFloat.random(in: 60...120)
            let particle = Particle(
                color: colors[i % colors.count],
                size: CGFloat.random(in: 4...8),
                targetOffset: CGSize(
                    width: Foundation.cos(angle) * distance,
                    height: Foundation.sin(angle) * distance
                )
            )
            particles.append(particle)
        }

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            for index in particles.indices {
                particles[index].offset = particles[index].targetOffset
                particles[index].scale = 0.3
                particles[index].opacity = 0
            }
        }
    }

    private func scheduleAutoDismiss() {
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }
}

// MARK: - Particle Model

private struct Particle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let targetOffset: CGSize
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
}

// MARK: - Checkmark Shape

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Start from left, go down to bottom-center, then up to top-right
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.50))
        path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.78))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.22))

        return path
    }
}

// MARK: - Preview

#Preview("Confirmation - With Delta") {
    CheckInConfirmationView(
        energyScore: 8,
        focusScore: 7,
        stressScore: 3,
        growthScore: 9,
        elapsedSeconds: 12,
        previousComposite: 7.0,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Confirmation - No Previous") {
    CheckInConfirmationView(
        energyScore: 6,
        focusScore: 5,
        stressScore: 6,
        growthScore: 5,
        elapsedSeconds: 28,
        previousComposite: nil,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
