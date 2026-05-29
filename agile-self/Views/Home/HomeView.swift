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
    @Environment(\.scenePhase) private var scenePhase

    let onShowSettings: () -> Void
    let onLogCheckIn: () -> Void
    /// Changes whenever the check-in cover dismisses; triggers a reload so a just-saved
    /// check-in is reflected immediately (CTA → "Today's score", rings, trend).
    var refreshToken: Int = 0

    // MARK: - ViewModel

    @State private var viewModel = HomeViewModel()

    // MARK: - Animation State

    @State private var dimensionsAppeared = false
    @State private var ctaPulse = false
    /// Bumped when the app returns to the foreground so the greeting/date/trend recompute
    /// after a day boundary (e.g. crossing midnight while backgrounded).
    @State private var dayRefreshToken = 0
    /// The calendar day Home last rendered; used to detect a midnight rollover cheaply.
    @State private var lastRenderedDay = Calendar.current.startOfDay(for: Date())

    // MARK: - Computed

    /// Reads `dayRefreshToken` so the time-derived greeting/date recompute when the token is
    /// bumped on foreground (post-midnight). Returns `now` for the actual computations.
    private var now: Date {
        _ = dayRefreshToken
        return Date()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var formattedDate: String {
        now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var isEvening: Bool {
        Calendar.current.component(.hour, from: now) >= 20
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
                    } else if !viewModel.hasAnyCheckIn {
                        firstRunHero
                    } else {
                        headerSection
                        scoreTrendSection
                        dimensionGridSection
                        aiInsightSection
                        todayConnectionSection
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
            .onChange(of: refreshToken) {
                // Reload after a check-in (the cover dismissed) so Home reflects it at once —
                // both the check-in data AND health (a saved check-in may have refreshed metrics).
                viewModel.loadData(context: modelContext)
                Task { await viewModel.loadHealthData(context: modelContext) }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                // Recompute the greeting/date on every foreground (cheap). If the calendar day
                // actually changed while backgrounded, also reload data so the trend reflects it.
                dayRefreshToken &+= 1
                let today = Calendar.current.startOfDay(for: Date())
                if today != lastRenderedDay {
                    lastRenderedDay = today
                    viewModel.loadData(context: modelContext)
                    Task { await viewModel.loadHealthData(context: modelContext) }
                }
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

    /// "Good morning, Alex" when a real name exists; just "Good morning" otherwise
    /// (no awkward ", there" fallback).
    private var greetingLine: String {
        if let name = viewModel.displayName {
            return "\(greeting), \(name)"
        }
        return greeting
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(greetingLine)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(formattedDate)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - First-Run Hero

    /// Shown only when the user has never logged a check-in. The trend chart, four rings,
    /// AI placeholder, health card, and today-summary are intentionally hidden here.
    private var firstRunHero: some View {
        VStack(spacing: Theme.Spacing.lg) {
            headerSection

            ZStack {
                // Soft glow drawn as a separate blurred disc so the shadow reads as light,
                // not a muddy halo over the translucent fill (cleaner in dark mode).
                Circle()
                    .fill(Theme.Colors.accentStart)
                    .opacity(0.18)
                    .blur(radius: 28)
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Theme.Colors.backgroundSecondary)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.accentGradient, lineWidth: 2)
                    )

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accentStart)
            }
            .frame(width: 120, height: 120)
            .padding(.top, Theme.Spacing.lg)

            Text("Let's take your first check-in")
                .font(Theme.Typography.title2)
                .multilineTextAlignment(.center)
                .gradientText()

            Text("Four quick questions about today — Energy, Focus, Calm, and Growth. About 15 seconds. Your trend starts the moment you finish.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.sm)

            Button(action: onLogCheckIn) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "pencil.line")
                    // Wording mirrors onboarding's "Start First Check-in" CTA for consistency.
                    Text("Start First Check-in")
                }
                .primaryButtonStyle()
            }
            .buttonStyle(.plain)
            // Keep this exact label — UI tests tap app.buttons["Start my first check-in"].
            .accessibilityLabel("Start my first check-in")

            Text("15 sec · 4 questions · every day")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            // Subtle secondary affordance — the tab bar is the real path to explore, this just
            // makes that discoverable instead of leaving the hero feeling like a dead end.
            Text("Or explore Insights and your Profile from the tabs below.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.Spacing.xs)
                .padding(.horizontal, Theme.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.lg)
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

    // MARK: - 4b. Today's Connection (mood ↔ health)

    /// Renders nothing unless there's a connection sentence (which needs a check-in AND today
    /// health data), so the simulator-without-seed and real-no-Health cases stay clean.
    private var todayConnectionSection: some View {
        TodayConnectionCard(
            connection: viewModel.todayConnection,
            health: viewModel.todayHealth
        )
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
                           let quality = health.sleepQualityLabel {
                            // Sits next to the "Sleep" duration card — label it "Sleep Quality"
                            // and lead with the quality word so a bare 0-100 isn't ambiguous.
                            HealthMetricCard(
                                icon: "moon.stars.fill",
                                value: "\(quality) · \(score)",
                                label: "Sleep Quality",
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

    /// Title shown when there's no health data — distinguishes a fetch error, "not yet
    /// authorized", and "authorized but nothing logged today".
    private var noHealthTitle: String {
        if viewModel.healthErrorMessage != nil {
            return "Health unavailable"
        }
        return viewModel.isHealthAuthorized ? "No health data for today yet" : "Connect Apple Health"
    }

    /// Detail copy paired with `noHealthTitle`.
    private var noHealthDetail: String {
        if let error = viewModel.healthErrorMessage {
            return error
        }
        return viewModel.isHealthAuthorized
            ? "Metrics appear here as your day is recorded. Pull to refresh anytime."
            : "Allow Health access to see your sleep, steps, and more."
    }

    /// Refresh-button label: prompts to grant access when not yet authorized, otherwise refreshes.
    private var noHealthButtonTitle: String {
        viewModel.isHealthAuthorized ? "Refresh" : "Allow Health Access"
    }

    private var noHealthDataView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: viewModel.healthErrorMessage != nil ? "heart.slash" : "heart.text.square")
                .font(.title3)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(noHealthTitle)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(noHealthDetail)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
            Button {
                // Not authorized → (re)request access then fetch. Authorized → just refetch.
                // Either way the in-flight spinner gives the tap visible feedback.
                Task {
                    await viewModel.loadHealthData(
                        context: modelContext,
                        requestAuthorization: !viewModel.isHealthAuthorized
                    )
                }
            } label: {
                Group {
                    if viewModel.isLoadingHealth {
                        ProgressView()
                            .tint(Theme.Colors.accentStart)
                    } else {
                        Text(noHealthButtonTitle)
                    }
                }
                .secondaryButtonStyle()
            }
            .disabled(viewModel.isLoadingHealth)
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(noHealthTitle). \(noHealthDetail)")
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

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Score: \(String(format: "%.1f", checkIn.compositeScore))")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Tap to edit your check-in")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
        // Keep the "Today's score is …" prefix — UI tests match buttons by this prefix.
        // Hint now reflects the real (edit) behavior instead of claiming "view details".
        .accessibilityLabel("Today's score is \(String(format: "%.1f", checkIn.compositeScore)).")
        .accessibilityHint("Tap to edit your check-in")
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
