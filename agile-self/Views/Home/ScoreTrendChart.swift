//
//  ScoreTrendChart.swift
//  agile-self
//
//  7-day composite score trend using Swift Charts.
//

import SwiftUI
import Charts

struct ScoreTrendChart: View {
    let checkIns: [DailyCheckIn]

    /// The latest plotted check-in is not guaranteed to be today's (the window can end on an
    /// earlier day). Only call it "Today" when it actually is.
    private var latestIsToday: Bool {
        guard let last = checkIns.last?.date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private var latestScore: Double? {
        checkIns.last?.compositeScore
    }

    /// Movement between the two most recent entries — only meaningful as a day-over-day delta
    /// when the latest entry is today AND the two are consecutive calendar days.
    private var scoreDelta: Double? {
        guard latestIsToday, checkIns.count >= 2 else { return nil }
        let last = checkIns[checkIns.count - 1]
        let prev = checkIns[checkIns.count - 2]
        guard let gap = Calendar.current.dateComponents([.day],
                                                         from: Calendar.current.startOfDay(for: prev.date),
                                                         to: Calendar.current.startOfDay(for: last.date)).day,
              gap == 1 else { return nil }
        return last.compositeScore - prev.compositeScore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            if checkIns.isEmpty {
                emptyState
            } else {
                chart
            }
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("7-DAY SCORE TREND")
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if let score = latestScore {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("\(latestIsToday ? "Today" : "Latest"): \(String(format: "%.1f", score))")
                        .font(Theme.Typography.scoreSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    if let delta = scoreDelta {
                        let trend = TrendDelta.classify(delta)
                        Text(deltaString(delta, trend: trend))
                            .font(Theme.Typography.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(trend.color)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(Theme.Colors.textTertiary)
            Text("No scores yet")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("Log your first check-in to start your trend")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No scores yet. Log your first check-in to start your trend.")
    }

    // MARK: - Chart

    private var chart: some View {
        // Marks are drawn unconditionally (no entrance-animation gate) so the trend is never
        // blank for Reduce Motion / VoiceOver users.
        Chart(checkIns, id: \.id) { checkIn in
            // Straight line + circle markers, no area fill — identical style to the Insights
            // chart and Apple Health's measurement line charts.
            LineMark(
                x: .value("Day", checkIn.date),
                y: .value("Score", checkIn.compositeScore)
            )
            .foregroundStyle(Theme.Colors.accentStart)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.linear)

            PointMark(
                x: .value("Day", checkIn.date),
                y: .value("Score", checkIn.compositeScore)
            )
            .foregroundStyle(Theme.Colors.accentStart)
            .symbolSize(40)
            .symbol(.circle)
        }
        // Apple Health line-chart grid (shared with Insights): leading-anchored 7-day window,
        // a weekday label at every column start, faint solid gridlines, Y axis on the right.
        .chartXScale(domain: ChartAxis.leadingDomain(spanDays: 7))
        .chartXAxis {
            AxisMarks(values: ChartAxis.dayLabelDates(spanDays: 7)) { value in
                AxisGridLine()
                    .foregroundStyle(Theme.Colors.divider.opacity(0.5))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
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
        .frame(height: 140)
        .accessibilityElement()
        .accessibilityLabel("7-day composite score trend")
        .accessibilityValue(
            latestScore.map {
                String(format: "%@ %.1f out of 5 across %d days.", latestIsToday ? "Today" : "Latest", $0, checkIns.count)
            } ?? "No data yet."
        )
    }

    // MARK: - Helpers

    private func deltaString(_ delta: Double, trend: TrendDelta) -> String {
        if trend == .neutral {
            return "\(trend.glyph) 0.0"
        }
        return "\(trend.glyph)\(String(format: "%.1f", abs(delta)))"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        ScoreTrendChart(checkIns: MockData.weeklyCheckIns)
            .padding(Theme.Spacing.md)
    }
}
