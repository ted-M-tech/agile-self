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
    case week = "W"
    case month = "M"
    case sixMonths = "6M"
    case year = "Y"

    /// Number of days the filtering window spans, inclusive of today.
    var windowDays: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 180
        case .year: return 365
        }
    }

    /// Inclusive day count for the FIXED chart x-domain (Apple Health style). Unlike
    /// `windowDays`, `.year` is a concrete 365 so the axis still spans a full, fixed window
    /// rather than collapsing onto whatever sparse data happens to exist.
    var spanDays: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 180
        case .year: return 365
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
    var onShowMonthlyReport: (() -> Void)?

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    // MARK: - ViewModel

    @State private var viewModel = InsightsViewModel()

    // MARK: - UI State

    @State private var selectedPeriod: TimePeriod = .week
    @State private var activeDimensions: Set<DimensionType> = []

    /// Check-ins filtered by the selected time period.
    private var filteredCheckIns: [DailyCheckIn] {
        viewModel.filteredCheckIns
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let error = viewModel.errorMessage {
                        ErrorStateView(message: error) {
                            viewModel.loadData(context: modelContext)
                        }
                    } else if viewModel.isLoading {
                        insightsLoadingView
                    } else if viewModel.allCheckIns.isEmpty {
                        insightsEmptyView
                    } else {
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
            // Apple Health layout: segmented period control on top, then an AVERAGE summary
            // (big number + inclusive date range), the chart, and finally the dimension toggles.
            periodPicker

            averageSummary

            // Main chart (or a hint when there is nothing to plot yet). The chart always uses a
            // fixed period grid, so even a single check-in renders correctly in its day column.
            if filteredCheckIns.isEmpty {
                trendEmptyHint
            } else {
                scoreChart
            }

            dimensionLegend
        }
        .cardStyle()
    }

    /// Apple Health-style summary: "AVERAGE / 3.4 avg score / May 23–29, 2026".
    private var averageSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("AVERAGE")
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .tracking(1.2)
                .foregroundStyle(Theme.Colors.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text(periodAverageText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("avg score")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Text(periodRangeText)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Average score \(periodAverageText) out of 5. \(periodRangeText).")
    }

    /// Average composite score across the selected window. "--" when there's nothing to average.
    private var periodAverageText: String {
        let scores = filteredCheckIns.map(\.compositeScore)
        guard !scores.isEmpty else { return "--" }
        return String(format: "%.1f", scores.reduce(0, +) / Double(scores.count))
    }

    /// Apple Health-style inclusive date range for the selected window, e.g. "May 23–29, 2026".
    private var periodRangeText: String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -(selectedPeriod.spanDays - 1), to: today) ?? today
        let year = today.formatted(.dateTime.year())
        if cal.isDate(start, equalTo: today, toGranularity: .month) {
            // Same month → "May 23–29, 2026"
            let month = start.formatted(.dateTime.month(.abbreviated))
            return "\(month) \(start.formatted(.dateTime.day()))–\(today.formatted(.dateTime.day())), \(year)"
        } else if cal.isDate(start, equalTo: today, toGranularity: .year) {
            // Same year → "Apr 30 – May 29, 2026"
            return "\(start.formatted(.dateTime.month(.abbreviated).day())) – \(today.formatted(.dateTime.month(.abbreviated).day())), \(year)"
        } else {
            // Cross-year → "Dec 1, 2025 – May 29, 2026"
            return "\(start.formatted(.dateTime.month(.abbreviated).day().year())) – \(today.formatted(.dateTime.month(.abbreviated).day().year()))"
        }
    }

    /// Day-start dates for the x-axis labels (shared helper → week labels every day).
    private var axisDates: [Date] {
        ChartAxis.dayLabelDates(spanDays: selectedPeriod.spanDays)
    }

    /// Spoken summary of the trend for VoiceOver (the chart marks themselves aren't readable).
    private var chartAccessibilitySummary: String {
        let scores = filteredCheckIns.map(\.compositeScore)
        guard let latest = scores.last, let lo = scores.min(), let hi = scores.max() else {
            return "No data yet."
        }
        return String(
            format: "Latest %.1f out of 5 across %d check-ins, ranging %.1f to %.1f.",
            latest, filteredCheckIns.count, lo, hi
        )
    }

    private var scoreChart: some View {
        Chart {
            ForEach(filteredCheckIns, id: \.id) { checkIn in
                // Marks are drawn unconditionally (no entrance-animation gate) so the chart is
                // never blank for Reduce Motion / VoiceOver users or on a view reuse.
                // Apple Health measurement line charts use STRAIGHT segments (no smoothing) and
                // NO area fill — just the line plus a circle marker at every reading.
                LineMark(
                        x: .value("Day", checkIn.date),
                        y: .value("Score", checkIn.compositeScore)
                    )
                    .foregroundStyle(Theme.Colors.accentStart)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.linear)

                    // Circle marker at every check-in (Apple Health style).
                    PointMark(
                        x: .value("Day", checkIn.date),
                        y: .value("Score", checkIn.compositeScore)
                    )
                    .foregroundStyle(Theme.Colors.accentStart)
                    .symbolSize(50)
                    .symbol(.circle)

                    // Optional dimension overlays
                    ForEach(Array(activeDimensions), id: \.self) { dimension in
                        LineMark(
                            x: .value("Day", checkIn.date),
                            y: .value(dimension.label, Double(checkIn.score(for: dimension))),
                            series: .value("Dimension", dimension.label)
                        )
                        .foregroundStyle(Theme.Dimension.color(for: dimension))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 3]))
                        .interpolationMethod(.linear)
                    }
            }
        }
        // Apple Health line-chart grid: domain anchored at the first day's start, so points and
        // weekday labels sit at column-START gridlines (left-aligned) and the right edge marks now.
        .chartXScale(domain: ChartAxis.leadingDomain(spanDays: selectedPeriod.spanDays))
        .chartXAxis {
            AxisMarks(values: axisDates) { value in
                // Faint SOLID vertical gridlines at each column start (Apple Health).
                AxisGridLine()
                    .foregroundStyle(Theme.Colors.divider.opacity(0.5))
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
            // Y axis on the trailing edge with subtle solid horizontal gridlines (Apple Health).
            AxisMarks(position: .trailing, values: [1, 2, 3, 4, 5]) { value in
                AxisGridLine()
                    .foregroundStyle(Theme.Colors.divider.opacity(0.7))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .chartYScale(domain: 1...5)
        .frame(height: 220)
        .accessibilityElement()
        .accessibilityLabel("Composite score trend")
        .accessibilityValue(chartAccessibilitySummary)
    }

    /// No check-ins in the selected window: a calm hint at the chart's height, instead of a
    /// broken-looking empty grid. (A single check-in now renders fine in `scoreChart` thanks to
    /// the fixed period domain, so there is no longer a separate single-point path.)
    private var trendEmptyHint: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title2)
                .foregroundStyle(Theme.Colors.textTertiary)
            Text("No check-ins in this period yet")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("Log a check-in to start your trend")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No check-ins in this period yet. Log a check-in to start your trend.")
    }

    /// Date format adapts to the selected period.
    private var xAxisFormat: Date.FormatStyle {
        switch selectedPeriod {
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.day()
        case .sixMonths, .year:
            return .dateTime.month(.abbreviated)
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
        // Expand the hit target to the 44pt minimum without enlarging the visible dot+label.
        .frame(minHeight: 44)
        .contentShape(Rectangle())
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
                .accessibilityAddTraits(.isHeader)

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
