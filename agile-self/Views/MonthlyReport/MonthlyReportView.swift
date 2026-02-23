//
//  MonthlyReportView.swift
//  agile-self
//
//  Monthly AI-generated report with overall gauge, trend chart, heatmap, and correlations.
//

import SwiftUI
import Charts

// MARK: - MonthlyReportView

struct MonthlyReportView: View {
    let onDismiss: () -> Void

    private let report = MockData.monthlyReport
    private let checkIns = MockData.monthlyCheckIns

    @State private var animateRing = false
    @State private var animateChart = false

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        overallScoreGauge
                        trendChartSection
                        heatmapSection
                        correlationsSection
                        executiveSummarySection
                        shareButton
                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.ringFill) {
                animateRing = true
            }
            withAnimation(Theme.Animation.trendLineDraw) {
                animateChart = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Monthly Report")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(monthYearTitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.backgroundTertiary)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = report.month
        components.year = report.year
        guard let date = Calendar.current.date(from: components) else { return "" }
        return formatter.string(from: date)
    }

    // MARK: - 1. Overall Score Gauge

    private var overallScoreGauge: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Theme.Colors.accentStart.opacity(0.15),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )

                // Animated fill ring
                Circle()
                    .trim(from: 0, to: animateRing ? ringProgress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Colors.accentStart, Theme.Colors.accentEnd, Theme.Colors.accentStart],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Score display
                VStack(spacing: Theme.Spacing.xs) {
                    Text(String(format: "%.1f", report.overallScore ?? 0))
                        .font(Theme.Typography.scoreDisplay)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Overall Score")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .frame(width: 160, height: 160)

            if let topInsight = report.topInsight {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.accentStart)

                    Text(topInsight)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall monthly score: \(String(format: "%.1f", report.overallScore ?? 0)) out of 10")
    }

    private var ringProgress: Double {
        (report.overallScore ?? 0) / 10.0
    }

    // MARK: - 2. Trend Chart (4-axis, 30 days)

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "30-DAY TRENDS", icon: "chart.xyaxis.line")

            if animateChart {
                Chart {
                    ForEach(checkIns, id: \.id) { checkIn in
                        ForEach(DimensionType.allCases) { dimension in
                            LineMark(
                                x: .value("Day", checkIn.date, unit: .day),
                                y: .value(dimension.label, Double(checkIn.score(for: dimension))),
                                series: .value("Dimension", dimension.label)
                            )
                            .foregroundStyle(Theme.Dimension.color(for: dimension))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.day()))
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

            // Dimension legend
            dimensionLegend
        }
        .cardStyle()
    }

    private var dimensionLegend: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(DimensionType.allCases) { dimension in
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Theme.Dimension.color(for: dimension))
                        .frame(width: 6, height: 6)

                    Text(dimension.label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(dimension.label) dimension")
            }
        }
    }

    // MARK: - 3. Heatmap Calendar

    private var heatmapSection: some View {
        HeatmapCalendarView(checkIns: checkIns)
    }

    // MARK: - 4. Correlations

    private var correlationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "CORRELATIONS", icon: "arrow.triangle.branch")

            ForEach(report.correlations) { correlation in
                correlationRow(correlation)
            }
        }
    }

    private func correlationRow(_ correlation: Correlation) -> some View {
        let isPositive = correlation.coefficient >= 0

        return HStack(spacing: Theme.Spacing.md) {
            // Arrow icon
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.title3)
                .foregroundStyle(isPositive ? Theme.Colors.success : Theme.Colors.warning)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(correlation.description)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("\(correlation.factor1) vs \(correlation.factor2)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(String(format: "%+.2f", correlation.coefficient))
                .font(Theme.Typography.scoreSmall)
                .foregroundStyle(isPositive ? Theme.Colors.success : Theme.Colors.warning)
        }
        .colorBorderCard(isPositive ? Theme.Colors.success : Theme.Colors.warning)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(correlation.description). Correlation: \(String(format: "%.2f", correlation.coefficient))")
    }

    // MARK: - 5. Executive Summary

    private var executiveSummarySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "EXECUTIVE SUMMARY", icon: "doc.text.fill")

            if let summary = report.executiveSummary {
                Text(summary)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
            }
        }
        .cardStyle()
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            // Share action placeholder
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "square.and.arrow.up")
                Text("Share Report")
            }
            .secondaryButtonStyle()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Share the monthly report via the share sheet")
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
    MonthlyReportView(onDismiss: {})
}
