//
//  ContentView.swift
//  agile-self Watch App
//
//  Home screen: score display, streak badge, check-in CTA.
//

import SwiftUI

struct ContentView: View {
    var connectivity: WatchConnectivityManager
    @State private var showCheckIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    Text("Agile Self")
                        .font(.headline)
                        .foregroundStyle(
                            WatchTheme.Colors.accentGradient
                        )

                    // Score or placeholder
                    if let score = connectivity.todayCompositeScore {
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", score))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(WatchTheme.Colors.textPrimary)

                            Text("Today's Score")
                                .font(.caption2)
                                .foregroundStyle(WatchTheme.Colors.textSecondary)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundStyle(WatchTheme.Colors.textTertiary)

                            Text("No check-in yet")
                                .font(.caption2)
                                .foregroundStyle(WatchTheme.Colors.textSecondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Streak badge
                    if connectivity.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(connectivity.currentStreak) day streak")
                                .font(.caption2)
                                .foregroundStyle(WatchTheme.Colors.textSecondary)
                        }
                    }

                    // Check-in button
                    if connectivity.didCheckInToday {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(WatchTheme.Colors.success)
                    } else {
                        Button {
                            showCheckIn = true
                        } label: {
                            Text("Check In")
                                .font(.footnote.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    WatchTheme.Colors.accentGradient,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(WatchTheme.Colors.backgroundPrimary)
            .sheet(isPresented: $showCheckIn) {
                WatchCheckInView(connectivity: connectivity)
            }
        }
    }
}

#Preview {
    ContentView(connectivity: WatchConnectivityManager())
}
