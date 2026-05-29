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
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    let onShowSettings: () -> Void
    let onLogCheckIn: () -> Void

    // MARK: - ViewModel

    @State private var viewModel = HomeViewModel()

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

    private var formattedDate: String {
        Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var isEvening: Bool {
        Calendar.current.component(.hour, from: Date()) >= 20
    }

    private var shouldShowCTAPulse: Bool {
        isEvening && viewModel.todayCheckIn == nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let error = viewModel.errorMessage {
                        errorStateView(message: error)
                    } else if viewModel.isLoading {
                        loadingStateView
                    } else {
                        headerSection
                        scoreTrendSection
                        dimensionGridSection
                        aiInsightSection
                        healthSection
                        checkInCTA
                    }
                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary)
            .scrollIndicators(.hidden)
            .refreshable {
                viewModel.loadData(context: modelContext)
                await viewModel.loadHealthData(context: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onShowSettings) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                viewModel.configure(
                    healthKitService: appContainer.healthKitService,
                    aiService: appContainer.aiService,
                    streakService: appContainer.streakService,
                    screenTimeService: appContainer.screenTimeService
                )
                viewModel.loadData(context: modelContext)
                await viewModel.loadHealthData(context: modelContext)
            }
        }
    }

    // MARK: - Loading State

    private var loadingStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: 100)
            ProgressView()
                .tint(Theme.Colors.accentStart)
                .scaleEffect(1.2)
            Text("Loading...")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textTertiary)
            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error State

    private func errorStateView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer(minLength: 80)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.warning)

            Text("Something went wrong")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(message)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.loadData(context: modelContext)
            } label: {
                Text("Try Again")
                    .secondaryButtonStyle()
            }
            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 1. Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("\(greeting), \(viewModel.userName)")
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
        ScoreTrendChart(checkIns: viewModel.weeklyCheckIns)
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
                    score: viewModel.todayCheckIn?.score(for: dimension)
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
        AIInsightCard(insight: viewModel.todayCheckIn?.dailyInsight)
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
                    if let health = viewModel.todayHealth {
                        if let sleep = health.formattedSleep {
                            HealthMetricCard(
                                icon: "bed.double.fill",
                                value: sleep,
                                label: "Sleep",
                                color: Theme.Colors.sleep
                            )
                        }
                        if let score = health.sleepScore,
                           let label = health.sleepQualityLabel {
                            HealthMetricCard(
                                icon: "moon.stars.fill",
                                value: "\(score)",
                                label: label,
                                color: Theme.Colors.sleep
                            )
                        }
                        if let steps = health.formattedSteps {
                            HealthMetricCard(
                                icon: "figure.walk",
                                value: steps,
                                label: "Steps",
                                color: Theme.Colors.steps
                            )
                        }
                        if let heartRate = health.formattedHeartRate {
                            HealthMetricCard(
                                icon: "heart.fill",
                                value: heartRate,
                                label: "Heart Rate",
                                color: Theme.Colors.heartRate
                            )
                        }
                        if let screenTime = health.formattedScreenTime {
                            HealthMetricCard(
                                icon: "iphone",
                                value: screenTime,
                                label: "Screen Time",
                                color: Theme.Colors.screenTime
                            )
                        }
                        if let runDist = health.formattedRunDistance {
                            HealthMetricCard(
                                icon: "figure.run",
                                value: runDist,
                                label: "Running",
                                color: Theme.Colors.running
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
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "heart.slash")
                .font(.title3)
                .foregroundStyle(Theme.Colors.textTertiary)
            Text("No health data available")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textTertiary)
            Text("Allow Health access, then pull to refresh")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.loadHealthData(context: modelContext) }
            } label: {
                Text("Refresh")
                    .secondaryButtonStyle()
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No health data available. Allow Health access, then pull to refresh.")
    }

    // MARK: - 6. Check-in CTA

    private var checkInCTA: some View {
        Group {
            if let checkIn = viewModel.todayCheckIn {
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
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
