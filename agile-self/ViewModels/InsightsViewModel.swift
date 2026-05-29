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
    /// AI-narrated, honest connection sentences derived from `correlations` (numbers stay
    /// deterministic). Empty until there's enough matched data — the UI then shows honest copy.
    var connections: [String] = []
    var patterns: [String] = []
    var streak: Streak?
    var monthlyReport: MonthlyReport?
    var isLoading = false
    var errorMessage: String?

    /// All health snapshots, cached from the last `loadData` so `loadConnections` can narrate
    /// without re-fetching. Computed over all data (the correlations themselves are all-time).
    private var allHealth: [HealthSnapshot] = []

    /// The currently selected time period for filtering.
    /// Default to `.week` so brand-new accounts see a sensible window instead of
    /// a sparse-looking 30-day chart on their first week.
    var selectedPeriod: TimePeriod = .week

    // MARK: - Services

    private var aiService: (any AIServiceProtocol)?
    private var streakService: StreakService?
    private var analyticsService: AnalyticsService?

    // MARK: - Init

    init(
        aiService: (any AIServiceProtocol)? = nil,
        streakService: StreakService? = nil,
        analyticsService: AnalyticsService? = nil
    ) {
        self.aiService = aiService
        self.streakService = streakService
        self.analyticsService = analyticsService
    }

    // MARK: - Configure Services

    func configure(
        aiService: any AIServiceProtocol,
        streakService: StreakService,
        analyticsService: AnalyticsService
    ) {
        self.aiService = aiService
        self.streakService = streakService
        self.analyticsService = analyticsService
    }

    // MARK: - Filtered Check-Ins

    var filteredCheckIns: [DailyCheckIn] {
        // Filter by calendar date, not by count: missing days must not pull in
        // older check-ins (suffix(7) on sparse data would reach weeks back).
        guard let start = selectedPeriod.startDate() else {
            return allCheckIns
        }
        return allCheckIns.filter { $0.date >= start }
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
                allHealth = healthSnapshots
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
        patterns = (try? await aiService.generatePatterns(from: allCheckIns)) ?? []
    }

    // MARK: - Load Connections

    /// AI-narrated connection sentences. Empty until there's enough matched data (the UI then
    /// shows honest "keep checking in" copy). Numbers stay deterministic. Call after `loadData`.
    func loadConnections() async {
        guard let aiService else { return }
        connections = (try? await aiService.generateConnections(
            checkIns: allCheckIns,
            health: allHealth
        )) ?? []
    }
}
