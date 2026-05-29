//
//  ShareContentBuilder.swift
//  agile-self
//
//  Builds plain-text share content from the persisted models. Pure (no SwiftUI,
//  services, or AI) so it is trivially testable and safe to call from a ShareLink.
//

import Foundation

enum ShareContentBuilder {

    /// Plain-text summary of a monthly report.
    static func monthlyReportText(_ report: MonthlyReport, checkIns: [DailyCheckIn]) -> String {
        var lines: [String] = []
        lines.append("Monthly Report \u{2014} \(monthYear(month: report.month, year: report.year))")
        if let score = report.overallScore {
            lines.append(String(format: "Overall Score: %.1f / 5", score))
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
