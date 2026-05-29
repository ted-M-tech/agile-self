//
//  ShareContentBuilder.swift
//  agile-self
//
//  Builds plain-text share content from the persisted models. Pure (no SwiftUI,
//  services, or AI) so it is trivially testable and safe to call from a ShareLink.
//

import Foundation

enum ShareContentBuilder {

    /// Plain-text summary of a completed weekly review.
    /// Suggested actions are intentionally omitted (they have no persisted home in M2).
    static func weeklySummaryText(_ review: WeeklyReview) -> String {
        var lines: [String] = []
        lines.append("Weekly Summary")
        lines.append(dateRange(start: review.weekStart, end: review.weekEnd))
        lines.append("")

        if !review.wins.isEmpty {
            lines.append("Wins")
            lines.append(contentsOf: review.wins.map { "\u{2022} \($0)" })
            lines.append("")
        }
        if !review.challenges.isEmpty {
            lines.append("Challenges")
            lines.append(contentsOf: review.challenges.map { "\u{2022} \($0)" })
            lines.append("")
        }
        if let summary = review.summary, !summary.isEmpty {
            lines.append("Summary")
            lines.append(summary)
            lines.append("")
        }
        if let takeaway = review.aiTakeaway, !takeaway.isEmpty {
            lines.append("AI Takeaway")
            lines.append(takeaway)
            lines.append("")
        }
        lines.append("\u{2014} Shared from Agile Self")
        return lines.joined(separator: "\n")
    }

    /// Plain-text summary of a monthly report.
    static func monthlyReportText(_ report: MonthlyReport, checkIns: [DailyCheckIn]) -> String {
        var lines: [String] = []
        lines.append("Monthly Report \u{2014} \(monthYear(month: report.month, year: report.year))")
        if let score = report.overallScore {
            lines.append(String(format: "Overall Score: %.1f / 10", score))
        }
        lines.append("Check-ins logged: \(checkIns.count)")
        lines.append("")

        if let insight = report.topInsight, !insight.isEmpty {
            lines.append("Top Insight")
            lines.append(insight)
            lines.append("")
        }

        // `correlation.description` is the model's STORED human-readable field.
        let correlations = report.correlations
        if !correlations.isEmpty {
            lines.append("Correlations")
            lines.append(contentsOf: correlations.map {
                "\u{2022} \($0.description) (\(String(format: "%+.2f", $0.coefficient)))"
            })
            lines.append("")
        }

        if let summary = report.executiveSummary, !summary.isEmpty {
            lines.append("Executive Summary")
            lines.append(summary)
            lines.append("")
        }
        lines.append("\u{2014} Shared from Agile Self")
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func dateRange(start: Date, end: Date) -> String {
        let startStr = start.formatted(.dateTime.month(.abbreviated).day())
        let endStr = end.formatted(.dateTime.month(.abbreviated).day())
        return "\(startStr) - \(endStr)"
    }

    private static func monthYear(month: Int, year: Int) -> String {
        var components = DateComponents()
        components.month = month
        components.year = year
        guard let date = Calendar.current.date(from: components) else { return "\(year)" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}
