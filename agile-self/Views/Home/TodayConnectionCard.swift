//
//  TodayConnectionCard.swift
//  agile-self
//
//  Surfaces the hidden connection between today's QUALITATIVE mood check-in and the user's
//  QUANTITATIVE Apple Health metrics, narrated by AI. The app's core differentiator on Home.
//
//  The card is shown ONLY when there is a connection sentence to display (which itself requires
//  a check-in AND today health data) — so the simulator-without-seed and real-no-Health cases
//  stay clean. Copy is correlational and honest; numbers are deterministic, never invented.
//

import SwiftUI

struct TodayConnectionCard: View {
    /// The AI-narrated connection sentence (nil → the card renders nothing).
    let connection: String?
    /// Today's health snapshot, used for the small supporting stat.
    let health: HealthSnapshot?

    var body: some View {
        if let connection {
            // Self-contained card matching AIInsightCard exactly (same padding / background /
            // radius / accent border) so the two AI cards on Home read as a unified pair. The
            // in-card "Mood meets Health" title (wand icon) is the parallel to "AI Insight"
            // (lightbulb); the former external "TODAY'S CONNECTION" section header is dropped.
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "wand.and.stars")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.accentStart)

                    Text("Mood meets Health")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text(connection)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                if let stat = supportingStat {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: stat.icon)
                            .font(.caption)
                            .foregroundStyle(stat.color)
                        Text(stat.text)
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, Theme.Spacing.xs)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Theme.Colors.accentStart.opacity(0.3), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today's connection: \(connection)")
        }
    }

    // MARK: - Supporting Stat

    private struct Stat {
        let icon: String
        let text: String
        let color: Color
    }

    /// One small, relevant supporting health stat — prefers sleep, then steps, then heart rate.
    private var supportingStat: Stat? {
        guard let health else { return nil }
        if let sleep = health.formattedSleep {
            return Stat(icon: "bed.double.fill", text: "Sleep \(sleep)", color: Theme.Colors.sleep)
        }
        if let steps = health.formattedSteps {
            return Stat(icon: "figure.walk", text: "\(steps) steps", color: Theme.Colors.steps)
        }
        if let hr = health.formattedHeartRate {
            return Stat(icon: "heart.fill", text: hr, color: Theme.Colors.heartRate)
        }
        if let run = health.formattedRunDistance {
            return Stat(icon: "figure.run", text: run, color: Theme.Colors.running)
        }
        return nil
    }
}

// MARK: - Preview

#Preview("With Connection") {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        TodayConnectionCard(
            connection: "You logged 7h 23m — and you tend to feel more focused after more sleep. Today's Focus: Good.",
            health: HealthSnapshot(sleepMinutes: 443, steps: 8421)
        )
        .padding(Theme.Spacing.md)
    }
}

#Preview("Hidden (no data)") {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        TodayConnectionCard(connection: nil, health: nil)
            .padding(Theme.Spacing.md)
    }
}
