//
//  MonthlyReportView.swift
//  agile-self
//
//  Monthly AI-generated report with overall gauge, trend chart, heatmap, and correlations.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - MonthlyReportView

struct MonthlyReportView: View {
    let onDismiss: () -> Void

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = MonthlyReportViewModel()
    @State private var animateRing = false
    @State private var animateChart = false

    private var report: MonthlyReport? { viewModel.report }
    private var checkIns: [DailyCheckIn] { viewModel.monthCheckIns }

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if viewModel.isLoading || viewModel.isGenerating {
                    loadingState
                } else if viewModel.isReportReady {
                    // A renderable report takes precedence over a transient load error so a
                    // re-load failure never blows away an already-generated report.
                    reportContent
                } else if let error = viewModel.errorMessage {
                    errorState(error)
                } else if viewModel.needsMoreCheckIns {
                    needsMoreDataState
                } else {
                    // ≥ threshold check-ins, but the report isn't generated yet (e.g. the model
                    // returned empty content this pass). Not an error, not "log more" — just pending.
                    reportPendingState
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            viewModel.configure(aiService: appContainer.aiService)
            await viewModel.loadData(context: modelContext)
        }
        .onAppear {
            withAnimation(Theme.Animation.ringFill) {
                animateRing = true
            }
            withAnimation(Theme.Animation.trendLineDraw) {
                animateChart = true
            }
        }
    }

    // MARK: - Loading / Empty States

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView()
                .tint(Theme.Colors.accentStart)
                .scaleEffect(1.2)
            Text(viewModel.isGenerating ? "Generating your report..." : "Loading...")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Shown while still below the check-in threshold (count < required). Distinguishes
    /// "no check-ins yet" from "a few logged, almost there" with explicit progress — instead
    /// of a meaningless 0.0 gauge with empty sections. (The count ≥ required case is handled
    /// separately by `reportPendingState`, so `remaining` here is always ≥ 1.)
    private var needsMoreDataState: some View {
        let count = viewModel.checkInCount
        let required = viewModel.minimumCheckInsToGenerate
        let remaining = max(0, required - count)

        return VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text(count == 0 ? "No check-ins yet this month" : "Building your report")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(insufficientDataMessage(count: count, required: required, remaining: remaining))
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Theme.Spacing.xl)

            if count > 0 {
                ProgressView(value: Double(min(count, required)), total: Double(required))
                    .tint(Theme.Colors.accentStart)
                    .frame(maxWidth: 180)
                    .padding(.top, Theme.Spacing.xs)

                Text("\(count) of \(required) check-ins")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(insufficientDataMessage(count: count, required: required, remaining: remaining))
    }

    private func insufficientDataMessage(count: Int, required: Int, remaining: Int) -> String {
        if count == 0 {
            return "Check in daily — your monthly report appears here once you've logged \(required) days."
        }
        return "Log \(remaining) more check-in\(remaining == 1 ? "" : "s") this month to unlock your AI-generated report with trends and patterns."
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
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
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                Task { await viewModel.loadData(context: modelContext) }
            } label: {
                Text("Try Again")
                    .secondaryButtonStyle()
            }
            .padding(.top, Theme.Spacing.sm)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Reached when there are enough check-ins (≥ threshold) but the report still isn't
    /// generated — e.g. the model returned empty content this pass. It will regenerate as more
    /// data accrues, so this is a calm "pending" state, not an error and not "log more".
    private var reportPendingState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Image(systemName: "hourglass")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("Your report is on its way")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("We couldn't put your report together just yet. Check back after your next check-in.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Theme.Spacing.xl)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your report is on its way. We couldn't put your report together just yet. Check back after your next check-in.")
    }

    // MARK: - Full Report

    private var reportContent: some View {
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
        let now = Calendar.current.dateComponents([.month, .year], from: Date())
        var components = DateComponents()
        components.month = report?.month ?? now.month
        components.year = report?.year ?? now.year
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
                    Text(String(format: "%.1f", report?.overallScore ?? 0))
                        .font(Theme.Typography.scoreDisplay)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Overall Score")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .frame(width: 160, height: 160)

            if let topInsight = report?.topInsight {
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
        .accessibilityLabel("Overall monthly score: \(String(format: "%.1f", report?.overallScore ?? 0)) out of 5")
    }

    private var ringProgress: Double {
        (report?.overallScore ?? 0) / 5.0
    }

    // MARK: - 2. Trend Chart (4-axis, 30 days)

    private var chartDates: [Date] { checkIns.map(\.date) }

    /// Pin to a full 30-day window so the month chart never crowds/garbles and
    /// reads consistently regardless of how many days were logged. The window
    /// ends at the latest check-in (or today) and spans 30 days back.
    private var chartDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let end = chartDates.max().map(calendar.startOfDay(for:)) ?? calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -29, to: end) ?? end
        // If real data starts later than the 30-day floor, still honor the
        // earliest point so a single day pads sensibly.
        let earliest = chartDates.min().map(calendar.startOfDay(for:)) ?? start
        let lower = min(start, earliest)
        guard lower < end else {
            let lo = calendar.date(byAdding: .hour, value: -12, to: end) ?? end
            let hi = calendar.date(byAdding: .hour, value: 12, to: end) ?? end
            return lo ... hi
        }
        return lower ... end
    }

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

                            // Visible point so a single day (or gaps) still show.
                            PointMark(
                                x: .value("Day", checkIn.date, unit: .day),
                                y: .value(dimension.label, Double(checkIn.score(for: dimension)))
                            )
                            .foregroundStyle(Theme.Dimension.color(for: dimension))
                            .symbolSize(checkIns.count <= 1 ? 36 : 10)
                        }
                    }
                }
                .chartXScale(domain: chartDomain)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: ChartAxis.dayStride(for: chartDates, desiredCount: 6))) { value in
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

    @ViewBuilder
    private var correlationsSection: some View {
        // Hide entirely when there are no correlations yet (e.g. no matched Health data),
        // rather than showing a lone header over empty space.
        if let correlations = report?.correlations, !correlations.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                sectionHeader(title: "CORRELATIONS", icon: "arrow.triangle.branch")

                ForEach(correlations) { correlation in
                    correlationRow(correlation)
                }
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

    @ViewBuilder
    private var executiveSummarySection: some View {
        // Only render the card when there is summary text — never a header-only empty card.
        if let summary = report?.executiveSummary, !summary.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                sectionHeader(title: "EXECUTIVE SUMMARY", icon: "doc.text.fill")

                Text(summary)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
            }
            .cardStyle()
        }
    }

    // MARK: - Share Button

    @ViewBuilder
    private var shareButton: some View {
        // Only offer sharing once the report is actually generated (avoids sharing an
        // empty/half-built report).
        if let report, report.isGenerated {
            ShareLink(
                item: ShareContentBuilder.monthlyReportText(report, checkIns: checkIns),
                subject: Text("My Monthly Report")
            ) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Report")
                }
                .secondaryButtonStyle()
            }
            .accessibilityHint("Share the monthly report via the share sheet")
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
    MonthlyReportView(onDismiss: {})
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
}
