//
//  HomeViewModel.swift
//  agile-self
//
//  ViewModel for the Home dashboard.
//  Loads check-ins, health data, streak, and user profile from SwiftData + services.
//

import Foundation
import os
import SwiftData

@Observable
final class HomeViewModel {

    // MARK: - Published State

    var weeklyCheckIns: [DailyCheckIn] = []
    var todayCheckIn: DailyCheckIn?
    /// True once the user has ever logged a check-in (lifetime, not the 7-day window).
    /// Drives the first-run hero vs. the full dashboard.
    var hasAnyCheckIn = false
    var todayHealth: HealthSnapshot?
    /// AI-narrated one-liner connecting today's standout health metric to today's mood. Nil
    /// when there's no health data (the "Today's connection" card is then hidden entirely).
    var todayConnection: String?
    var streak: Streak?
    var userProfile: UserProfile?
    /// Full-screen loading state — only true on the genuine first data load, so subsequent
    /// reloads (pull-to-refresh, post-check-in) refresh in place without a spinner takeover.
    var isLoading = false
    /// Critical error: the check-ins query failed. This blanks the dashboard (the data is gone).
    var errorMessage: String?
    /// Non-critical error from the health fetch. Surfaced inline on the health card only —
    /// it must NOT blank the whole dashboard.
    var healthErrorMessage: String?
    /// True while a health fetch is in flight. Drives the Refresh button's transient spinner
    /// and guards against overlapping fetches (pull-to-refresh + Refresh button).
    var isLoadingHealth = false
    /// Whether HealthKit reported readable data on the most recent fetch. Lets the no-data
    /// view decide between "grant access" (request auth) and "no data yet" (just refresh).
    var isHealthAuthorized = false
    /// True once the first data load has completed (so we never show the big spinner again).
    private var hasCompletedInitialLoad = false

    // MARK: - Services

    private var healthKitService: HealthKitService?
    private var aiService: (any AIServiceProtocol)?
    private var streakService: StreakService?
    private var screenTimeService: ScreenTimeService?

    // MARK: - Init

    init(
        healthKitService: HealthKitService? = nil,
        aiService: (any AIServiceProtocol)? = nil,
        streakService: StreakService? = nil,
        screenTimeService: ScreenTimeService? = nil
    ) {
        self.healthKitService = healthKitService
        self.aiService = aiService
        self.streakService = streakService
        self.screenTimeService = screenTimeService
    }

    // MARK: - Configure Services

    func configure(
        healthKitService: HealthKitService,
        aiService: any AIServiceProtocol,
        streakService: StreakService,
        screenTimeService: ScreenTimeService
    ) {
        self.healthKitService = healthKitService
        self.aiService = aiService
        self.streakService = streakService
        self.screenTimeService = screenTimeService
    }

    // MARK: - Load Data

    func loadData(context: ModelContext) {
        // Only show the full-screen spinner on the genuine first load. Later reloads
        // (pull-to-refresh, post-check-in via refreshToken) refresh content in place.
        if !hasCompletedInitialLoad {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isLoading = false
            hasCompletedInitialLoad = true
        }

        do {
            // Fetch weekly check-ins (last 7 days)
            let calendar = Calendar.current
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!

            var checkInDescriptor = FetchDescriptor<DailyCheckIn>(
                predicate: #Predicate<DailyCheckIn> { checkIn in
                    checkIn.date >= sevenDaysAgo
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            checkInDescriptor.fetchLimit = 7
            weeklyCheckIns = try context.fetch(checkInDescriptor)

            // Find today's check-in
            let today = calendar.startOfDay(for: Date())
            todayCheckIn = weeklyCheckIns.first { calendar.isDate($0.date, inSameDayAs: today) }

            // Lifetime "has the user ever checked in?" — independent of the 7-day window
            // so the first-run hero only shows when there is genuinely no history.
            var existenceDescriptor = FetchDescriptor<DailyCheckIn>()
            existenceDescriptor.fetchLimit = 1
            hasAnyCheckIn = ((try? context.fetch(existenceDescriptor))?.first) != nil

            // Fetch user profile
            let profileDescriptor = FetchDescriptor<UserProfile>()
            userProfile = try context.fetch(profileDescriptor).first

            // Fetch streak
            if let streakService {
                streak = streakService.fetchOrCreateStreak(context: context)
            } else {
                let streakDescriptor = FetchDescriptor<Streak>()
                streak = try context.fetch(streakDescriptor).first
            }
        } catch {
            errorMessage = "Unable to load your data. Please try restarting the app."
        }
    }

    // MARK: - Load Health Data

    /// Fetches today's health snapshot. Optionally re-requests HealthKit authorization first
    /// (used when the user taps Refresh from the no-data view and access was never granted).
    ///
    /// Health data is non-critical: failures populate `healthErrorMessage` (shown inline on
    /// the health card) but never the dashboard-blanking `errorMessage`.
    func loadHealthData(context: ModelContext, requestAuthorization: Bool = false) async {
        guard let healthKitService else { return }

        // Guard against overlapping fetches (pull-to-refresh + Refresh button at once).
        guard !isLoadingHealth else { return }
        isLoadingHealth = true

        healthErrorMessage = nil

        do {
            // Re-prompt for authorization only when explicitly asked (first run always prompts
            // once via the initial load; the no-data Refresh button can re-trigger it).
            if requestAuthorization || !healthKitService.hasRequestedAuthorization {
                try await healthKitService.requestAuthorization()
            }

            // Always attempt the fetch — HealthKit doesn't report authorization status,
            // and a denied/empty fetch degrades gracefully to nil metrics.
            let snapshot = try await healthKitService.fetchTodaySnapshot()

            // Merge screen time from App Group shared UserDefaults (nil on the free tier).
            if let screenTimeService, let screenMinutes = screenTimeService.fetchTodayScreenTime() {
                snapshot.screenTimeMinutes = screenMinutes
            }

            isHealthAuthorized = healthKitService.isAuthorized
            todayHealth = snapshot
            // Only persist when there's real data — avoid storing empty snapshots.
            if snapshot.hasAnyMetric || snapshot.screenTimeMinutes != nil {
                persistHealthSnapshot(snapshot, context: context)
            }
        } catch {
            // Non-critical: keep the dashboard intact, surface the failure on the card only.
            healthErrorMessage = "Couldn't read Health data right now. Pull to refresh to try again."
            AppLog.health.notice("home health fetch failed (non-critical) — dashboard preserved")
        }

        // ALWAYS build today's connection from the source of truth (SwiftData). This runs even
        // when the live fetch threw or returned nothing, so a previously stored snapshot — real
        // prior data, or UITEST_SEED — still drives both the connection card and (when the live
        // fetch was empty) the health metric cards. Clears any stale health error if it succeeds.
        await loadTodayConnection(context: context)
        if todayConnection != nil { healthErrorMessage = nil }
        isLoadingHealth = false
    }

    // MARK: - Today's Connection

    /// Builds the AI-narrated one-liner linking today's standout health metric to today's mood.
    ///
    /// Reads today's HealthSnapshot from SwiftData (the source of truth — this includes data
    /// seeded under UITEST_SEED, where the live HealthKit fetch returns nothing on the simulator)
    /// and the user's historical correlations over all data, so the sentence can lean on an
    /// established pattern when one exists. Sets `todayConnection` to nil when there's no
    /// check-in or no health data (the card is then hidden).
    func loadTodayConnection(context: ModelContext) async {
        guard let aiService, let checkIn = todayCheckIn else {
            todayConnection = nil
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        do {
            // Prefer the persisted snapshot for today (includes seeded data); fall back to the
            // freshly fetched in-memory snapshot when nothing is stored yet.
            let healthDescriptor = FetchDescriptor<HealthSnapshot>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            let allHealth = try context.fetch(healthDescriptor)
            let storedToday = allHealth.first { calendar.isDate($0.date, inSameDayAs: today) }
            let snapshotForToday = storedToday ?? todayHealth

            guard let snapshotForToday, snapshotForToday.hasAnyMetric else {
                todayConnection = nil
                return
            }

            // When the live fetch returned nothing (e.g. simulator / HealthKit unavailable) but
            // a stored snapshot exists (real prior data, or UITEST_SEED), surface that snapshot so
            // both the health metric cards and the connection card show consistent data.
            if todayHealth?.hasAnyMetric != true {
                todayHealth = snapshotForToday
            }

            // Historical correlations over all data, so the sentence can reference an
            // established pattern. Numbers stay deterministic (AnalyticsService).
            let checkInDescriptor = FetchDescriptor<DailyCheckIn>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            let allCheckIns = try context.fetch(checkInDescriptor)
            let correlations = AnalyticsService().detectCorrelations(checkIns: allCheckIns, health: allHealth)

            todayConnection = try await aiService.generateTodayConnection(
                checkIn: checkIn,
                todayHealth: snapshotForToday,
                correlations: correlations
            )
        } catch {
            todayConnection = nil
        }
    }

    // MARK: - Persist Health Snapshot

    /// Upserts today's HealthSnapshot into SwiftData (match by date, update if exists, insert if new).
    private func persistHealthSnapshot(_ snapshot: HealthSnapshot, context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<HealthSnapshot>(
            predicate: #Predicate<HealthSnapshot> { $0.date == today }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                // Update existing snapshot
                existing.sleepMinutes = snapshot.sleepMinutes
                existing.steps = snapshot.steps
                existing.activeCalories = snapshot.activeCalories
                existing.exerciseMinutes = snapshot.exerciseMinutes
                existing.restingHeartRate = snapshot.restingHeartRate
                existing.runningDistanceMeters = snapshot.runningDistanceMeters
                existing.screenTimeMinutes = snapshot.screenTimeMinutes
            } else {
                // Insert new snapshot
                context.insert(snapshot)
            }
            try context.save()
        } catch {
            // Persistence failure is non-critical
        }
    }

    // MARK: - Computed

    /// The user's display name, or nil when none is set. Nil lets the header drop the
    /// awkward ", there" fallback and show just the greeting ("Good morning").
    var displayName: String? {
        guard let name = userProfile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return nil
        }
        return name
    }
}
