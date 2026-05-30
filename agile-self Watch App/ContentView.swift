//
//  ContentView.swift
//  agile-self Watch App
//
//  Minimal home: today's status, the streak, and one big "Check In" CTA. Once checked in,
//  the CTA is replaced by a calm "Done" state showing today's composite score.
//

import SwiftUI

struct ContentView: View {
    var connectivity: WatchConnectivityManager
    @State private var showCheckIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Agile Self")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(WatchTheme.Colors.accentGradient)

                    statusSection

                    if connectivity.currentStreak > 0 {
                        streakBadge
                    }

                    if connectivity.didCheckInToday {
                        doneState
                    } else {
                        checkInButton
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(WatchTheme.Colors.backgroundPrimary)
        }
        .sheet(isPresented: $showCheckIn) {
            WatchCheckInView(connectivity: connectivity)
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        if connectivity.didCheckInToday, let score = connectivity.todayCompositeScore {
            VStack(spacing: 2) {
                // Word-first headline mapped from the 1–5 composite (matches iOS).
                Text(watchCompositeWord(for: score))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(WatchTheme.Colors.textSecondary)

                // Bold typographic hero: a big rounded numeral in the accent gradient.
                Text(String(format: "%.1f", score))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchTheme.Colors.accentGradient)
                    .contentTransition(.numericText())

                Text("Today's score")
                    .font(.caption2)
                    .foregroundStyle(WatchTheme.Colors.textSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(format: "%@. Today's score %.1f out of 5.", watchCompositeWord(for: score), score))
        } else {
            VStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(WatchTheme.Colors.textTertiary)
                Text("No check-in yet")
                    .font(.caption)
                    .foregroundStyle(WatchTheme.Colors.textSecondary)
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Streak

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundStyle(WatchTheme.Dimension.energy)
            Text("\(connectivity.currentStreak) day streak")
                .font(.caption2)
                .foregroundStyle(WatchTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(WatchTheme.Colors.backgroundTertiary, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(connectivity.currentStreak) day streak")
    }

    // MARK: - Done State

    private var doneState: some View {
        Label("Checked in", systemImage: "checkmark.circle.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(WatchTheme.Colors.success)
            .padding(.top, 2)
            .accessibilityLabel("Checked in today")
    }

    // MARK: - CTA

    private var checkInButton: some View {
        Button {
            showCheckIn = true
        } label: {
            Text("Check In")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(WatchTheme.Colors.accentGradient, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start daily check-in")
    }
}

// MARK: - Previews

#Preview("Not checked in") {
    ContentView(connectivity: WatchConnectivityManager())
        .preferredColorScheme(.dark)
}

#Preview("Checked in") {
    let manager = WatchConnectivityManager()
    manager.didCheckInToday = true
    manager.todayCompositeScore = 3.8
    manager.currentStreak = 5
    return ContentView(connectivity: manager)
        .preferredColorScheme(.dark)
}
