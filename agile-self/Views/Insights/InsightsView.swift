//
//  InsightsView.swift
//  agile-self
//
//  Insights tab showing score trends, health correlations, AI patterns, and streak data.
//

import SwiftUI
import Charts

// MARK: - Time Period

enum TimePeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

// MARK: - Insights View

struct InsightsView: View {
    @State private var selectedPeriod: TimePeriod = .month
    @State private var activeDimensions: Set<DimensionType> = []
    @State private var animateChart = false

    private let checkIns = MockData.monthlyCheckIns
    private let report = MockData.monthlyReport
    private let streak = MockData.streak

    /// Check-ins filtered by the selected time period.
    private var filteredCheckIns: [DailyCheckIn] {
        switch selectedPeriod {
        case .week:
            return Array(checkIns.suffix(7))
        case .month:
            return Array(checkIns.suffix(30))
        case .quarter:
            return Array(checkIns.suffix(30)) // Mock: only 30 days available
        case .year:
            return checkIns
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    periodPicker
                    scoreTrendSection
                    correlationsSection
                    patternsSection
                    streakSection
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
        }
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

            // Main chart
            scoreChart

            // Dimension toggles
            dimensionLegend
        }
        .cardStyle()
    }

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
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
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
            AxisMarks(position: .leading, values: [2, 4, 6, 8, 10]) { value in
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
        .chartYScale(domain: 1...10)
        .frame(height: 200)
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

    // MARK: - Correlations Section

    private var correlationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "HEALTH CORRELATIONS", icon: "arrow.triangle.branch")

            ForEach(report.correlations) { correlation in
                CorrelationCard(correlation: correlation)
            }
        }
    }

    // MARK: - AI Patterns Section

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "AI PATTERNS", icon: "brain.head.profile.fill")

            PatternCard(
                title: "Focus peaks on run days",
                description: "Your focus scores are 23% higher on days you go for a run."
            )

            PatternCard(
                title: "Sleep affects stress",
                description: "Sleep quality below 7h correlates with higher stress the next day."
            )

            PatternCard(
                title: "Midweek energy dip",
                description: "Wednesday is consistently your lowest energy day.",
                icon: "chart.line.downtrend.xyaxis"
            )
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "STREAK", icon: "flame.fill")

            HStack(spacing: Theme.Spacing.sm) {
                streakStatCard(
                    value: "\(streak.currentStreak)",
                    label: "Current",
                    icon: "flame.fill",
                    color: Theme.Colors.warning
                )

                streakStatCard(
                    value: "\(streak.longestStreak)",
                    label: "Longest",
                    icon: "trophy.fill",
                    color: Theme.Dimension.energy
                )

                streakStatCard(
                    value: "\(streak.totalCheckIns)",
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
        .preferredColorScheme(.dark)
}
