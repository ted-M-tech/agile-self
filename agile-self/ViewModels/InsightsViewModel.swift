//
//  InsightsViewModel.swift
//  agile-self
//
//  ViewModel for the Insights tab.
//  Loads check-ins, correlations, AI patterns, and streak data.
//

import Foundation
import SwiftData

@Observable
final class InsightsViewModel {

    // MARK: - Published State

    var allCheckIns: [DailyCheckIn] = []
    var correlations: [Correlation] = []
    var patterns: [String] = []
    var streak: Streak?
    var monthlyReport: MonthlyReport?
    var isLoading = false
    var errorMessage: String?

    /// The currently selected time period for filtering.
    var selectedPeriod: TimePeriod = .month

    // MARK: - Services

    private var aiService: AIService?
    private var streakService: StreakService?
    private var analyticsService: AnalyticsService?

    // MARK: - Init

    init(
        aiService: AIService? = nil,
        streakService: StreakService? = nil,
        analyticsService: AnalyticsService? = nil
    ) {
        self.aiService = aiService
        self.streakService = streakService
        self.analyticsService = analyticsService
    }

    // MARK: - Configure Services

    func configure(
        aiService: AIService,
        streakService: StreakService,
        analyticsService: AnalyticsService
    ) {
        self.aiService = aiService
        self.streakService = streakService
        self.analyticsService = analyticsService
    }

    // MARK: - Filtered Check-Ins

    var filteredCheckIns: [DailyCheckIn] {
        switch selectedPeriod {
        case .week:
            return Array(allCheckIns.suffix(7))
        case .month:
            return Array(allCheckIns.suffix(30))
        case .quarter:
            return Array(allCheckIns.suffix(90))
        case .year:
            return allCheckIns
        }
    }

    // MARK: - Load Data

    func loadData(context: ModelContext) {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Fetch all check-ins sorted by date
            let checkInDescriptor = FetchDescriptor<DailyCheckIn>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            allCheckIns = try context.fetch(checkInDescriptor)

            // Compute correlations from real HealthSnapshot data via AnalyticsService
            if let analyticsService {
                let healthDescriptor = FetchDescriptor<HealthSnapshot>(
                    sortBy: [SortDescriptor(\.date, order: .forward)]
                )
                let healthSnapshots = try context.fetch(healthDescriptor)
                let detected = analyticsService.detectCorrelations(
                    checkIns: allCheckIns,
                    health: healthSnapshots
                )
                correlations = detected
            }

            // Fallback to MonthlyReport correlations if AnalyticsService found none
            if correlations.isEmpty {
                var reportDescriptor = FetchDescriptor<MonthlyReport>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                reportDescriptor.fetchLimit = 1
                monthlyReport = try context.fetch(reportDescriptor).first
                correlations = monthlyReport?.correlations ?? []
            }

            // Fetch streak
            if let streakService {
                streak = streakService.fetchOrCreateStreak(context: context)
            } else {
                let streakDescriptor = FetchDescriptor<Streak>()
                streak = try context.fetch(streakDescriptor).first
            }
        } catch {
            errorMessage = "Unable to load insights. Please try restarting the app."
        }
    }

    // MARK: - Load AI Patterns

    func loadPatterns() async {
        guard let aiService else { return }
        patterns = await aiService.generatePatterns(from: allCheckIns)
    }
}
