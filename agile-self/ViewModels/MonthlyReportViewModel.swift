//
//  MonthlyReportViewModel.swift
//  agile-self
//
//  ViewModel for the Monthly Report. Fetches the current month's check-ins, finds or
//  lazily creates the MonthlyReport row, and generates it on-device exactly once per
//  month (once enough data exists). Replaces the previous MockData-backed view.
//

import Foundation
import SwiftData

@Observable
final class MonthlyReportViewModel {

    // MARK: - Published State

    var report: MonthlyReport?
    var monthCheckIns: [DailyCheckIn] = []
    var isLoading = false
    var isGenerating = false
    var errorMessage: String?

    /// Minimum check-ins before a report is generated, so a 1-2 check-in month is not
    /// frozen at a meaningless score.
    let minimumCheckInsToGenerate = 3

    /// Number of check-ins logged this month.
    var checkInCount: Int { monthCheckIns.count }

    /// True only once a real report has been generated (≥ `minimumCheckInsToGenerate`
    /// check-ins + non-empty AI content). The full report UI is gated on this so a sparse
    /// month never renders a meaningless 0.0 gauge + empty sections.
    /// NOTE: do NOT gate the full report on "has ≥1 check-in" — a 1–2 check-in month is
    /// intentionally NOT ready (that was the 0.0-gauge bug).
    var isReportReady: Bool { report?.isGenerated == true }

    /// Still collecting the minimum check-ins needed before a report can be generated.
    var needsMoreCheckIns: Bool { checkInCount < minimumCheckInsToGenerate }

    // MARK: - Services

    private var aiService: (any AIServiceProtocol)?

    // MARK: - Init / Configure

    init(aiService: (any AIServiceProtocol)? = nil) {
        self.aiService = aiService
    }

    func configure(aiService: any AIServiceProtocol) {
        self.aiService = aiService
    }

    // MARK: - Load

    func loadData(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        guard let monthStart = calendar.date(from: comps),
              let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart),
              let month = comps.month,
              let year = comps.year else {
            return
        }

        do {
            // Check-ins for the current calendar month, fetched FIRST.
            let checkInDescriptor = FetchDescriptor<DailyCheckIn>(
                predicate: #Predicate<DailyCheckIn> { $0.date >= monthStart && $0.date < nextMonthStart },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            monthCheckIns = try context.fetch(checkInDescriptor)

            // Existing report for this month/year (best-effort dedup; no unique constraint).
            let reportDescriptor = FetchDescriptor<MonthlyReport>(
                predicate: #Predicate<MonthlyReport> { $0.month == month && $0.year == year }
            )
            report = try context.fetch(reportDescriptor).first

            // No data → don't create an orphan empty report row.
            guard !monthCheckIns.isEmpty else { return }

            // Create the report row lazily, only once there is data.
            let activeReport: MonthlyReport
            if let existing = report {
                activeReport = existing
            } else {
                let created = MonthlyReport(month: month, year: year)
                context.insert(created)
                report = created
                activeReport = created
            }

            // Generate exactly once, with a re-entrancy guard and a data-sufficiency gate.
            if !isGenerating,
               !activeReport.isGenerated,
               monthCheckIns.count >= minimumCheckInsToGenerate {
                await generate(
                    report: activeReport,
                    monthStart: monthStart,
                    nextMonthStart: nextMonthStart,
                    context: context
                )
            }
        } catch {
            errorMessage = "Unable to load your monthly report."
        }
    }

    // MARK: - Generate

    private func generate(
        report: MonthlyReport,
        monthStart: Date,
        nextMonthStart: Date,
        context: ModelContext
    ) async {
        guard let aiService else { return }
        isGenerating = true
        defer { isGenerating = false }

        let healthDescriptor = FetchDescriptor<HealthSnapshot>(
            predicate: #Predicate<HealthSnapshot> { $0.date >= monthStart && $0.date < nextMonthStart },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let health = (try? context.fetch(healthDescriptor)) ?? []

        do {
            let result = try await aiService.generateMonthlyReport(checkIns: monthCheckIns, health: health)

            // If the model produced no real content, leave isGenerated = false so the
            // report regenerates as more data accrues later this month.
            let hasContent = !result.executiveSummary.isEmpty || !result.topInsight.isEmpty

            report.executiveSummary = result.executiveSummary
            report.topInsight = result.topInsight
            report.overallScore = result.overallScore
            report.setCorrelations(result.correlations)
            report.isGenerated = hasContent
            report.generatedAt = Date()
            try context.save()
        } catch {
            errorMessage = "Unable to generate your monthly report."
        }
    }
}
