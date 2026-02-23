//
//  HeatmapCalendarView.swift
//  agile-self
//
//  GitHub-contribution-graph style heatmap for 30 days of composite scores.
//

import SwiftUI

// MARK: - HeatmapCalendarView

struct HeatmapCalendarView: View {
    let checkIns: [DailyCheckIn]

    private let columns = 7 // Days per row (M T W T F S S)
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// Maps each date to its composite score for quick lookup.
    private var scoreByDate: [String: Double] {
        var map: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for checkIn in checkIns {
            map[formatter.string(from: checkIn.date)] = checkIn.compositeScore
        }
        return map
    }

    /// Generates 30 calendar days ending today, aligned to a weekday grid.
    private var calendarDays: [CalendarDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Build 30 days ending today
        var days: [CalendarDay] = []
        for daysAgo in stride(from: 29, through: 0, by: -1) {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let key = formatter.string(from: date)
            let score = scoreByDate[key]
            let weekday = calendar.component(.weekday, from: date) // 1=Sun, 2=Mon...
            // Convert to Mon=0, Tue=1, ... Sun=6
            let columnIndex = (weekday + 5) % 7
            days.append(CalendarDay(date: date, score: score, columnIndex: columnIndex))
        }
        return days
    }

    /// Rows of calendar days for the grid layout.
    private var calendarRows: [[CalendarDay?]] {
        var rows: [[CalendarDay?]] = []
        var currentRow: [CalendarDay?] = Array(repeating: nil, count: columns)
        var rowStarted = false

        for day in calendarDays {
            if rowStarted && day.columnIndex == 0 {
                rows.append(currentRow)
                currentRow = Array(repeating: nil, count: columns)
            }
            currentRow[day.columnIndex] = day
            rowStarted = true
        }
        rows.append(currentRow)

        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("DAILY HEATMAP")
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)

            // Weekday header labels
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Heatmap grid
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(calendarRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(0..<columns, id: \.self) { col in
                            if let day = row[col] {
                                heatmapCell(day: day)
                            } else {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.clear)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }

            // Legend
            heatmapLegend
        }
        .cardStyle()
    }

    // MARK: - Heatmap Cell

    private func heatmapCell(day: CalendarDay) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(cellColor(for: day.score))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityLabel(cellAccessibilityLabel(day: day))
    }

    private func cellColor(for score: Double?) -> Color {
        guard let score else {
            return Theme.Colors.backgroundTertiary
        }
        // Map score 1-10 to opacity 0.15-1.0
        let normalizedScore = (score - 1.0) / 9.0
        let clampedScore = max(0, min(normalizedScore, 1.0))

        // Blend from dim accent to full accent
        return Theme.Colors.accentStart.opacity(0.15 + clampedScore * 0.85)
    }

    private func cellAccessibilityLabel(day: CalendarDay) -> String {
        let dateStr = day.date.formatted(.dateTime.month(.abbreviated).day())
        if let score = day.score {
            return "\(dateStr): score \(String(format: "%.1f", score))"
        }
        return "\(dateStr): no data"
    }

    // MARK: - Legend

    private var heatmapLegend: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Spacer()

            Text("Less")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            HStack(spacing: 3) {
                ForEach([0.15, 0.35, 0.55, 0.75, 1.0], id: \.self) { opacity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.accentStart.opacity(opacity))
                        .frame(width: 12, height: 12)
                }
            }

            Text("More")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }
}

// MARK: - Calendar Day

private struct CalendarDay {
    let date: Date
    let score: Double?
    let columnIndex: Int
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        HeatmapCalendarView(checkIns: MockData.monthlyCheckIns)
            .padding(Theme.Spacing.md)
    }
    .preferredColorScheme(.dark)
}
