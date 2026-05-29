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

    private var todayScore: Double? {
        checkIns.last?.compositeScore
    }

    private var scoreDelta: Double? {
        guard checkIns.count >= 2 else { return nil }
        let today = checkIns[checkIns.count - 1].compositeScore
        let yesterday = checkIns[checkIns.count - 2].compositeScore
        return today - yesterday
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            if checkIns.isEmpty {
                emptyState
            } else if checkIns.count == 1 {
                singlePointChart
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

            if let score = todayScore {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Today: \(String(format: "%.1f", score))")
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

    private var dates: [Date] { checkIns.map(\.date) }

    private var chart: some View {
        // Marks are drawn unconditionally (no entrance-animation gate) so the trend is never
        // blank for Reduce Motion / VoiceOver users.
        Chart(checkIns, id: \.id) { checkIn in
            AreaMark(
                x: .value("Day", checkIn.date, unit: .day),
                y: .value("Score", checkIn.compositeScore)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Theme.Colors.accentStart.opacity(0.3),
                        Theme.Colors.accentStart.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Day", checkIn.date, unit: .day),
                y: .value("Score", checkIn.compositeScore)
            )
            .foregroundStyle(Theme.Colors.accentStart)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            .interpolationMethod(.catmullRom)

            // Always-visible point at every check-in so a sparse line still
            // shows where the data is; the final point is emphasized.
            PointMark(
                x: .value("Day", checkIn.date, unit: .day),
                y: .value("Score", checkIn.compositeScore)
            )
            .foregroundStyle(
                checkIn.id == checkIns.last?.id
                    ? Theme.Colors.accentEnd
                    : Theme.Colors.accentStart
            )
            .symbolSize(checkIn.id == checkIns.last?.id ? 40 : 18)
        }
        .chartXScale(domain: ChartAxis.dateDomain(for: dates))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: ChartAxis.dayStride(for: dates, desiredCount: 7))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 1...5)
        .frame(height: 120)
        .accessibilityElement()
        .accessibilityLabel("7-day composite score trend")
        .accessibilityValue(
            todayScore.map { String(format: "Today %.1f out of 5 across %d days.", $0, checkIns.count) }
                ?? "No data yet."
        )
    }

    /// Exactly one check-in: a lone line is invisible, so show the point plus a
    /// hint instead of an empty-looking axis.
    private var singlePointChart: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Chart(checkIns, id: \.id) { checkIn in
                PointMark(
                    x: .value("Day", checkIn.date, unit: .day),
                    y: .value("Score", checkIn.compositeScore)
                )
                .foregroundStyle(Theme.Colors.accentEnd)
                .symbolSize(60)
            }
            .chartXScale(domain: ChartAxis.dateDomain(for: dates))
            .chartXAxis {
                AxisMarks(values: dates) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartYScale(domain: 1...5)
            .frame(height: 96)

            Text("Keep checking in to see your trend")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
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
