//
//  InsightsView.swift
//  agile-self
//
//  Insights tab showing score trends, health correlations, AI patterns, and streak data.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Time Period

enum TimePeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"

    /// Number of days the filtering window spans, inclusive of today.
    /// `nil` means "all time" (no lower bound).
    var windowDays: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return nil
        }
    }

    /// The inclusive lower-bound date (stripped to midnight) for this period,
    /// computed relative to `reference`. Check-ins whose `date` is `>= start`
    /// belong to the window. Returns `nil` for `.year` (no lower bound).
    func startDate(
        relativeTo reference: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        guard let days = windowDays else { return nil }
        let today = calendar.startOfDay(for: reference)
        return calendar.date(byAdding: .day, value: -(days - 1), to: today)
    }
}

// MARK: - Insights View

struct InsightsView: View {
    var onShowWeeklyReview: (() -> Void)?
    var onShowMonthlyReport: (() -> Void)?

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    // MARK: - ViewModel

    @State private var viewModel = InsightsViewModel()

    // MARK: - UI State

    @State private var selectedPeriod: TimePeriod = .week
    @State private var activeDimensions: Set<DimensionType> = []
    @State private var animateChart = false

    /// Check-ins filtered by the selected time period.
    private var filteredCheckIns: [DailyCheckIn] {
        viewModel.filteredCheckIns
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let error = viewModel.errorMessage {
                        insightsErrorView(message: error)
                    } else if viewModel.isLoading {
                        insightsLoadingView
                    } else if viewModel.allCheckIns.isEmpty {
                        insightsEmptyView
                    } else {
                        periodPicker
                        scoreTrendSection
                        connectionsSection
                        patternsSection
                        streakSection
                        reviewActionsSection
                    }
                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Insights")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(Theme.Animation.trendLineDraw) {
                    animateChart = true
                }
            }
            .task {
                viewModel.configure(
                    aiService: appContainer.aiService,
                    streakService: appContainer.streakService,
                    analyticsService: appContainer.analyticsService
                )
                viewModel.loadData(context: modelContext)
                await viewModel.loadPatterns()
                await viewModel.loadConnections()
            }
            .onChange(of: selectedPeriod) { _, newValue in
                viewModel.selectedPeriod = newValue
            }
        }
    }

    // MARK: - Loading State

    private var insightsLoadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: 100)
            ProgressView()
                .tint(Theme.Colors.accentStart)
                .scaleEffect(1.2)
            Text("Loading insights...")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textTertiary)
            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error State

    private func insightsErrorView(message: String) -> some View {
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

    // MARK: - Empty State

    private var insightsEmptyView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer(minLength: 60)
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.accentStart.opacity(0.5))

            Text("No Check-ins Yet")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Start logging daily check-ins to see trends, patterns, and AI-powered insights here.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Score Trend Chart

    private var scoreTrendSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "SCORE TREND", icon: "chart.xyaxis.line")

            // Main chart (or a hint when there is nothing to plot yet)
            if filteredCheckIns.count <= 1 {
                singlePointChart
            } else {
                scoreChart
            }

            // Dimension toggles
            dimensionLegend
        }
        .cardStyle()
    }

    /// Dates actually being plotted, for pinning the x-domain / stride.
    private var chartDates: [Date] { filteredCheckIns.map(\.date) }

    private var scoreChart: some View {
        Chart {
            ForEach(filteredCheckIns, id: \.id) { checkIn in
                if animateChart {
                    // Area fill under composite line
                    AreaMark(
                        x: .value("Day", checkIn.date, unit: .day),
                        y: .value("Score", checkIn.compositeScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accentStart.opacity(0.3),
                                Theme.Colors.accentStart.opacity(0.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    // Main composite line
                    LineMark(
                        x: .value("Day", checkIn.date, unit: .day),
                        y: .value("Score", checkIn.compositeScore)
                    )
                    .foregroundStyle(Theme.Colors.accentStart)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    // Always-visible composite point so sparse data is legible.
                    PointMark(
                        x: .value("Day", checkIn.date, unit: .day),
                        y: .value("Score", checkIn.compositeScore)
                    )
                    .foregroundStyle(Theme.Colors.accentStart)
                    .symbolSize(18)

                    // Optional dimension overlays
                    ForEach(Array(activeDimensions), id: \.self) { dimension in
                        LineMark(
                            x: .value("Day", checkIn.date, unit: .day),
                            y: .value(dimension.label, Double(checkIn.score(for: dimension))),
                            series: .value("Dimension", dimension.label)
                        )
                        .foregroundStyle(Theme.Dimension.color(for: dimension))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 3]))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
        }
        .chartXScale(domain: ChartAxis.dateDomain(for: chartDates))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: ChartAxis.dayStride(for: chartDates, desiredCount: 6))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.formatted(xAxisFormat))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                AxisGridLine()
                    .foregroundStyle(Theme.Colors.divider)
            }
        }
        .chartYScale(domain: 1...5)
        .frame(height: 200)
    }

    /// 0–1 points: a line/area is invisible. Show the single point (if any) on a
    /// pinned axis with a hint, instead of a broken-looking empty chart.
    private var singlePointChart: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Chart {
                ForEach(filteredCheckIns, id: \.id) { checkIn in
                    PointMark(
                        x: .value("Day", checkIn.date, unit: .day),
                        y: .value("Score", checkIn.compositeScore)
                    )
                    .foregroundStyle(Theme.Colors.accentStart)
                    .symbolSize(60)
                }
            }
            .chartXScale(domain: ChartAxis.dateDomain(for: chartDates))
            .chartXAxis {
                AxisMarks(values: chartDates) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(xAxisFormat))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    AxisGridLine()
                        .foregroundStyle(Theme.Colors.divider)
                }
            }
            .chartYScale(domain: 1...5)
            .frame(height: 200)

            Text("Keep checking in to see your trend")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    /// Date format adapts to the selected period.
    private var xAxisFormat: Date.FormatStyle {
        switch selectedPeriod {
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.day()
        case .quarter, .year:
            return .dateTime.month(.abbreviated).day()
        }
    }

    private var dimensionLegend: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Composite (always shown)
            legendItem(label: "Composite", color: Theme.Colors.accentStart, isActive: true, isToggleable: false)

            ForEach(DimensionType.allCases) { dimension in
                legendItem(
                    label: dimension.label,
                    color: Theme.Dimension.color(for: dimension),
                    isActive: activeDimensions.contains(dimension),
                    isToggleable: true
                ) {
                    withAnimation(Theme.Animation.standard) {
                        if activeDimensions.contains(dimension) {
                            activeDimensions.remove(dimension)
                        } else {
                            activeDimensions.insert(dimension)
                        }
                    }
                }
            }
        }
    }

    private func legendItem(
        label: String,
        color: Color,
        isActive: Bool,
        isToggleable: Bool,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(isActive ? color : color.opacity(0.3))
                    .frame(width: 6, height: 6)

                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(isActive ? Theme.Colors.textSecondary : Theme.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isToggleable)
        .accessibilityLabel("\(label) dimension")
        .accessibilityAddTraits(isToggleable ? .isButton : .isStaticText)
        .accessibilityValue(isActive ? "visible" : "hidden")
    }

    // MARK: - Connections Section

    /// AI-narrated, honest "Connections" between health metrics and how the user feels —
    /// replaces the over-promising bare-coefficient correlation list.
    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "CONNECTIONS", icon: "wand.and.stars")

            if viewModel.connections.isEmpty {
                // Honest waiting state — correlation needs ~a week of matched check-in + Health data.
                Text("Keep checking in with Apple Health connected — after about a week I'll start showing how your sleep, steps, and activity line up with how you feel.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
                    .padding(.vertical, Theme.Spacing.md)
            } else {
                // The narrator builds connections from `correlations.prefix(3)` in order, so the
                // i-th sentence aligns with the i-th correlation for the supporting arrow.
                ForEach(Array(viewModel.connections.enumerated()), id: \.offset) { index, sentence in
                    ConnectionCard(
                        sentence: sentence,
                        correlation: index < viewModel.correlations.count ? viewModel.correlations[index] : nil
                    )
                }
            }
        }
    }

    // MARK: - AI Patterns Section

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "AI PATTERNS", icon: "brain.head.profile.fill")

            if viewModel.patterns.isEmpty {
                Text("Patterns will be discovered as you log more check-ins.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.vertical, Theme.Spacing.md)
            } else {
                ForEach(Array(viewModel.patterns.enumerated()), id: \.offset) { _, pattern in
                    PatternCard(
                        title: pattern,
                        description: ""
                    )
                }
            }
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "STREAK", icon: "flame.fill")

            HStack(spacing: Theme.Spacing.sm) {
                streakStatCard(
                    value: "\(viewModel.streak?.currentStreak ?? 0)",
                    label: "Current",
                    icon: "flame.fill",
                    color: Theme.Colors.warning
                )

                streakStatCard(
                    value: "\(viewModel.streak?.longestStreak ?? 0)",
                    label: "Longest",
                    icon: "trophy.fill",
                    color: Theme.Dimension.energy
                )

                streakStatCard(
                    value: "\(viewModel.streak?.totalCheckIns ?? 0)",
                    label: "Total",
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success
                )
            }
        }
    }

    private func streakStatCard(
        value: String,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(Theme.Typography.scoreMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Review Actions

    private var reviewActionsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if let onShowWeeklyReview {
                Button(action: onShowWeeklyReview) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.Dimension.focus)

                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Weekly AI Review")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Text("Reflect on your week with AI coaching")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start Weekly AI Review")
            }

            if let onShowMonthlyReport {
                Button(action: onShowMonthlyReport) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "doc.text.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.Dimension.growth)

                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Monthly Report")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Text("View your AI-generated growth report")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View Monthly Report")
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Theme.Colors.accentStart)

            Text(title)
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
