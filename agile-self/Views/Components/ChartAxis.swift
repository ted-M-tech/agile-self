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
