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

    @State private var animateChart = false

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
            chart
        }
        .cardStyle()
        .onAppear {
            withAnimation(Theme.Animation.trendLineDraw) {
                animateChart = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("7-DAY SCORE TREND")
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)

            Spacer()

            if let score = todayScore {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Today: \(String(format: "%.1f", score))")
                        .font(Theme.Typography.scoreSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    if let delta = scoreDelta {
                        Text(deltaString(delta))
                            .font(Theme.Typography.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(delta >= 0 ? Theme.Colors.success : Theme.Colors.error)
                    }
                }
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(checkIns, id: \.id) { checkIn in
            if animateChart {
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

                if checkIn.id == checkIns.last?.id {
                    PointMark(
                        x: .value("Day", checkIn.date, unit: .day),
                        y: .value("Score", checkIn.compositeScore)
                    )
                    .foregroundStyle(Theme.Colors.accentEnd)
                    .symbolSize(40)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
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
        .chartYScale(domain: 1...10)
        .frame(height: 120)
    }

    // MARK: - Helpers

    private func deltaString(_ delta: Double) -> String {
        let arrow = delta >= 0 ? "\u{25B2}" : "\u{25BC}"
        return "\(arrow)\(String(format: "%.1f", abs(delta)))"
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
