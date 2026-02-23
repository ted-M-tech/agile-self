//
//  HomeView.swift
//  agile-self
//
//  Home Dashboard with score trends, dimension cards, AI insights, and health data.
//

import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    let onShowSettings: () -> Void
    let onLogCheckIn: () -> Void

    // MARK: - Mock Data (prototype: swap to @Query for production)

    @State private var weeklyCheckIns = MockData.weeklyCheckIns
    @State private var todayCheckIn: DailyCheckIn? = MockData.todayCheckIn
    @State private var todayHealth: HealthSnapshot? = MockData.todayHealth
    @State private var streak = MockData.streak

    // MARK: - Animation State

    @State private var dimensionsAppeared = false
    @State private var ctaPulse = false

    // MARK: - Computed

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var userName: String {
        MockData.userProfile.displayName ?? "there"
    }

    private var formattedDate: String {
        Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var isEvening: Bool {
        Calendar.current.component(.hour, from: Date()) >= 20
    }

    private var shouldShowCTAPulse: Bool {
        isEvening && todayCheckIn == nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection
                    scoreTrendSection
                    dimensionGridSection
                    aiInsightSection
                    healthSection
                    checkInCTA
                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onShowSettings) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 1. Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("\(greeting), \(userName)")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(formattedDate)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - 2. Score Trend

    private var scoreTrendSection: some View {
        ScoreTrendChart(checkIns: weeklyCheckIns)
    }

    // MARK: - 3. Dimension Grid

    private var dimensionGridSection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.md
        ) {
            ForEach(Array(DimensionType.allCases.enumerated()), id: \.element) { index, dimension in
                DimensionCard(
                    dimension: dimension,
                    score: todayCheckIn?.score(for: dimension) ?? 0
                )
                .opacity(dimensionsAppeared ? 1 : 0)
                .offset(y: dimensionsAppeared ? 0 : 20)
                .animation(
                    Theme.Animation.stagger(index: index),
                    value: dimensionsAppeared
                )
            }
        }
        .onAppear {
            dimensionsAppeared = true
        }
    }

    // MARK: - 4. AI Insight

    private var aiInsightSection: some View {
        AIInsightCard(insight: todayCheckIn?.dailyInsight)
    }

    // MARK: - 5. Health Metrics

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("TODAY'S HEALTH")
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)
                .padding(.leading, Theme.Spacing.xs)

            ScrollView(.horizontal) {
                HStack(spacing: Theme.Spacing.sm) {
                    if let health = todayHealth {
                        if let sleep = health.formattedSleep {
                            HealthMetricCard(
                                icon: "bed.double.fill",
                                value: sleep,
                                label: "Sleep",
                                color: .indigo
                            )
                        }
                        if let steps = health.formattedSteps {
                            HealthMetricCard(
                                icon: "figure.walk",
                                value: steps,
                                label: "Steps",
                                color: .orange
                            )
                        }
                        if let heartRate = health.formattedHeartRate {
                            HealthMetricCard(
                                icon: "heart.fill",
                                value: heartRate,
                                label: "Heart Rate",
                                color: .red
                            )
                        }
                        if let screenTime = health.formattedScreenTime {
                            HealthMetricCard(
                                icon: "iphone",
                                value: screenTime,
                                label: "Screen Time",
                                color: .cyan
                            )
                        }
                        if let runDist = health.formattedRunDistance {
                            HealthMetricCard(
                                icon: "figure.run",
                                value: runDist,
                                label: "Running",
                                color: .green
                            )
                        }
                    } else {
                        noHealthDataView
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
    }

    private var noHealthDataView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "heart.slash")
                .foregroundStyle(Theme.Colors.textTertiary)
            Text("No health data available")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
    }

    // MARK: - 6. Check-in CTA

    private var checkInCTA: some View {
        Group {
            if let checkIn = todayCheckIn {
                todayScoreSummary(checkIn)
            } else {
                logCheckInButton
            }
        }
    }

    private func todayScoreSummary(_ checkIn: DailyCheckIn) -> some View {
        Button(action: onLogCheckIn) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.success)

                Text("Today's Score: \(String(format: "%.1f", checkIn.compositeScore))")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Today's score is \(String(format: "%.1f", checkIn.compositeScore)). Tap to view details.")
    }

    private var logCheckInButton: some View {
        Button(action: onLogCheckIn) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "pencil.line")
                Text("Log Today's Score")
            }
            .primaryButtonStyle()
        }
        .buttonStyle(.plain)
        .scaleEffect(ctaPulse ? 1.02 : 1.0)
        .onAppear {
            if shouldShowCTAPulse {
                withAnimation(Theme.Animation.ctaPulse) {
                    ctaPulse = true
                }
            }
        }
        .accessibilityLabel("Log today's score")
        .accessibilityHint("Opens the daily check-in form")
    }
}

// MARK: - Preview

#Preview {
    HomeView(onShowSettings: {}, onLogCheckIn: {})
        .modelContainer(MockData.previewContainer)
        .preferredColorScheme(.dark)
}
