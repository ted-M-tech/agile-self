//
//  ChartAxis.swift
//  agile-self
//
//  Shared helpers for Swift Charts correctness across all chart surfaces.
//
//  Root causes addressed (the "29 29 29 29" bug):
//    - No pinned x-domain → auto AxisMarks collapse duplicate day labels.
//    - Line/Area-only marks → a single data point renders nothing visible.
//    - No 0–1 point state → the axis looks broken on a brand-new account.
//
//  Every date-based chart should:
//    1. Pin `.chartXScale(domain:)` to `dateDomain` of the plotted check-ins.
//    2. Use `dateAxisMarks(...)` for non-repeating, strided day labels.
//    3. Always render a `PointMark` so a single point is visible.
//    4. Branch on `count <= 1` to show a "keep checking in" hint.
//

import SwiftUI
import Charts

// MARK: - Date Axis Configuration

/// Computes a pinned, non-degenerate x-domain and a sensible label stride for a
/// date-based chart, given the dates actually being plotted.
enum ChartAxis {

    /// A closed date range to feed `.chartXScale(domain:)`.
    ///
    /// Guarantees a non-degenerate range even for 0 or 1 points so the axis and
    /// any single `PointMark` are placed sensibly instead of collapsing onto one
    /// tick (which produces the repeated-label bug).
    static func dateDomain(
        for dates: [Date],
        fallbackSpanDays: Int = 6,
        calendar: Calendar = .current
    ) -> ClosedRange<Date> {
        let sorted = dates.sorted()
        let today = calendar.startOfDay(for: Date())

        guard let first = sorted.first, let last = sorted.last else {
            // 0 points: show a tidy trailing window ending today.
            let start = calendar.date(byAdding: .day, value: -fallbackSpanDays, to: today) ?? today
            return start ... today
        }

        let lower = calendar.startOfDay(for: first)
        let upper = calendar.startOfDay(for: last)

        guard lower < upper else {
            // Exactly 1 distinct day: pad ±half-day so the point sits centered and
            // the axis renders a single, real tick rather than a collapsed stack.
            let lo = calendar.date(byAdding: .hour, value: -12, to: lower) ?? lower
            let hi = calendar.date(byAdding: .hour, value: 12, to: lower) ?? lower
            return lo ... hi
        }
        return lower ... upper
    }

    /// A day stride that keeps the x-axis from crowding/garbling.
    /// Roughly targets `desiredCount` labels across the span.
    static func dayStride(
        for dates: [Date],
        desiredCount: Int = 6,
        calendar: Calendar = .current
    ) -> Int {
        let sorted = dates.sorted()
        guard let first = sorted.first, let last = sorted.last else { return 1 }
        let lo = calendar.startOfDay(for: first)
        let hi = calendar.startOfDay(for: last)
        let spanDays = max(1, (calendar.dateComponents([.day], from: lo, to: hi).day ?? 0))
        return max(1, Int((Double(spanDays) / Double(max(1, desiredCount))).rounded(.up)))
    }

    // MARK: - Fixed (period-anchored) domain — Apple Health style

    /// A FIXED x-domain spanning the whole period and ending today, INDEPENDENT of how many
    /// points exist. Like Apple Health's weekly/monthly charts: the grid always shows the full
    /// window, so a lone data point sits in its real day column instead of floating to the edge
    /// (the "single point looks broken" bug). `spanDays` is the inclusive day count (Week=7,
    /// Month=30, …). Days are padded ±12h so each day is centered in its column and an edge
    /// point is never clipped.
    static func fixedDomain(
        spanDays: Int,
        calendar: Calendar = .current,
        reference: Date = Date()
    ) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: reference)
        let start = calendar.date(byAdding: .day, value: -(max(1, spanDays) - 1), to: today) ?? today
        let lo = calendar.date(byAdding: .hour, value: -12, to: start) ?? start
        let hi = calendar.date(byAdding: .hour, value: 12, to: today) ?? today
        return lo ... hi
    }

    /// Day-label stride for a FIXED span (vs `dayStride`, which derives from the data extent).
    /// Targets `desiredCount` labels across the full window so labels never crowd.
    static func fixedStride(spanDays: Int, desiredCount: Int = 6) -> Int {
        max(1, Int((Double(max(1, spanDays)) / Double(max(1, desiredCount))).rounded(.up)))
    }

    /// Apple Health line-chart domain: anchored at the FIRST day's start (so daily points and
    /// weekday labels sit at column-START gridlines, left-aligned like Apple Health) with a
    /// trailing day to today+1 that marks "now" on the right. A small left inset keeps the first
    /// point's marker from clipping at the edge.
    static func leadingDomain(
        spanDays: Int,
        calendar: Calendar = .current,
        reference: Date = Date()
    ) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: reference)
        let firstDay = calendar.date(byAdding: .day, value: -(max(1, spanDays) - 1), to: today) ?? today
        let lo = calendar.date(byAdding: .hour, value: -6, to: firstDay) ?? firstDay
        let hi = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return lo ... hi
    }

    /// Day-start dates for x-axis labels, anchored at each column start (Apple Health style) and
    /// thinned so labels never crowd. A week (≤7 days) labels EVERY day (Sat…Fri); longer spans
    /// are strided toward ~6 labels. Shared by Home and Insights so the axis reads identically.
    static func dayLabelDates(
        spanDays: Int,
        calendar: Calendar = .current,
        reference: Date = Date()
    ) -> [Date] {
        let today = calendar.startOfDay(for: reference)
        let span = max(1, spanDays)
        let step = span <= 7 ? 1 : fixedStride(spanDays: span, desiredCount: 6)
        var dates: [Date] = []
        var offset = span - 1
        while offset >= 0 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) { dates.append(date) }
            offset -= step
        }
        return dates
    }
}

// MARK: - Single-Point Hint

/// A tasteful inline hint shown in place of a broken-looking axis when there are
/// 0–1 data points. Uses Theme tokens and sits at the same height as the chart.
struct ChartTrendHint: View {
    var message: String = "Keep checking in to see your trend"
    var height: CGFloat = 120

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title3)
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(message)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Delta Semantics

/// Classifies a score delta into neutral / positive / negative using a small
/// dead-band so a trivial change (or exactly zero) is not mislabeled as "up".
enum TrendDelta {
    case neutral
    case up
    case down

    /// |delta| below this is treated as neutral (no real movement).
    static let neutralBand: Double = 0.05

    static func classify(_ delta: Double) -> TrendDelta {
        if abs(delta) < neutralBand { return .neutral }
        return delta > 0 ? .up : .down
    }

    /// SF Symbol-free glyph for the delta badge.
    var glyph: String {
        switch self {
        case .neutral: return "\u{2013}" // en dash (flat)
        case .up: return "\u{25B2}"       // ▲
        case .down: return "\u{25BC}"     // ▼
        }
    }

    var color: Color {
        switch self {
        case .neutral: return Theme.Colors.textSecondary
        case .up: return Theme.Colors.success
        case .down: return Theme.Colors.warning
        }
    }
}
