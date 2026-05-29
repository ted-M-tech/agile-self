//
//  WeeklyReviewIntroView.swift
//  agile-self
//
//  Weekly review intro screen with sparkline-style summary and per-axis bars.
//

import SwiftUI
import Charts

// MARK: - WeeklyReviewIntroView

struct WeeklyReviewIntroView: View {
    let checkIns: [DailyCheckIn]
    let onStartReview: () -> Void
    let onSkip: () -> Void

    @State private var animateBars = false

    private var averageComposite: Double {
        guard !checkIns.isEmpty else { return 0 }
        return checkIns.reduce(0.0) { $0 + $1.compositeScore } / Double(checkIns.count)
    }

    private func dimensionAverage(_ dimension: DimensionType) -> Double {
        guard !checkIns.isEmpty else { return 0 }
        return Double(checkIns.reduce(0) { $0 + $1.score(for: dimension) }) / Double(checkIns.count)
    }

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                header
                sparklineSection
                dimensionBarsSection
                Spacer()
                actionButtons
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.ringFill) {
                animateBars = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.accentGradient)
                .padding(.top, Theme.Spacing.xl)

            Text("Weekly Review")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(weekDateRange)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var weekDateRange: String {
        guard let first = checkIns.first, let last = checkIns.last else { return "" }
        let startStr = first.date.formatted(.dateTime.month(.abbreviated).day())
        let endStr = last.date.formatted(.dateTime.month(.abbreviated).day())
        return "\(startStr) - \(endStr)"
    }

    // MARK: - Sparkline

    private var sparklineSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("COMPOSITE SCORE")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .tracking(1.2)

                Spacer()

                Text("Avg: \(String(format: "%.1f", averageComposite))")
                    .font(Theme.Typography.scoreSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            if checkIns.count <= 1 {
                sparklineSinglePoint
            } else {
                sparkline
            }
        }
        .cardStyle()
    }

    private var sparklineDates: [Date] { checkIns.map(\.date) }

    /// True sparkline: pinned domain, always-visible points, minimal weekday
    /// labels strided so they never repeat/garble.
    private var sparkline: some View {
        Chart(checkIns, id: \.id) { checkIn in
            LineMark(
                x: .value("Day", checkIn.date, unit: .day),
                y: .value("Score", checkIn.compositeScore)
            )
            .foregroundStyle(Theme.Colors.accentStart)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            .interpolationMethod(.catmullRom)

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

            PointMark(
                x: .value("Day", checkIn.date, unit: .day),
                y: .value("Score", checkIn.compositeScore)
            )
            .foregroundStyle(Theme.Colors.accentStart)
            .symbolSize(16)
        }
        .chartXScale(domain: ChartAxis.dateDomain(for: sparklineDates))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: ChartAxis.dayStride(for: sparklineDates, desiredCount: 7))) { value in
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
        .frame(height: 100)
    }

    /// 0–1 points: render the lone point (if any) on a pinned axis with a hint.
    private var sparklineSinglePoint: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Chart(checkIns, id: \.id) { checkIn in
                PointMark(
                    x: .value("Day", checkIn.date, unit: .day),
                    y: .value("Score", checkIn.compositeScore)
                )
                .foregroundStyle(Theme.Colors.accentEnd)
                .symbolSize(50)
            }
            .chartXScale(domain: ChartAxis.dateDomain(for: sparklineDates))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 1...5)
            .frame(height: 76)

            Text("Keep checking in to see your trend")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Dimension Bars

    private var dimensionBarsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("PER-AXIS AVERAGES")
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)

            ForEach(DimensionType.allCases) { dimension in
                dimensionBarRow(dimension)
            }
        }
        .cardStyle()
    }

    private func dimensionBarRow(_ dimension: DimensionType) -> some View {
        let avg = dimensionAverage(dimension)
        let fraction = avg / 5.0

        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: dimension.icon)
                .font(.caption)
                .foregroundStyle(Theme.Dimension.color(for: dimension))
                .frame(width: 20)

            Text(dimension.label)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.Dimension.background(for: dimension))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.Dimension.color(for: dimension))
                        .frame(
                            width: animateBars ? geometry.size.width * fraction : 0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f", avg))
                .font(Theme.Typography.scoreSmall)
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 32, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dimension.label): average \(String(format: "%.1f", avg)) out of 5")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button(action: onStartReview) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Start AI Review ~3-5 min")
                }
                .primaryButtonStyle()
            }
            .buttonStyle(.plain)
            .accessibilityHint("Begin the AI-guided weekly review conversation")

            Button(action: onSkip) {
                Text("Skip & view summary")
                    .ghostButtonStyle()
            }
            .buttonStyle(.plain)
            .accessibilityHint("Skip the review and see an auto-generated summary")
        }
        .padding(.bottom, Theme.Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    WeeklyReviewIntroView(
        checkIns: MockData.weeklyCheckIns,
        onStartReview: {},
        onSkip: {}
    )
}
