//
//  HomeViewModel.swift
//  agile-self
//
//  ViewModel for the Home dashboard.
//  Loads check-ins, health data, streak, and user profile from SwiftData + services.
//

import Foundation
import SwiftData

@Observable
final class HomeViewModel {

    // MARK: - Published State

    var weeklyCheckIns: [DailyCheckIn] = []
    var todayCheckIn: DailyCheckIn?
    var todayHealth: HealthSnapshot?
    var streak: Streak?
    var userProfile: UserProfile?
    var isLoading = false
    var errorMessage: String?

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
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

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

    func loadHealthData(context: ModelContext) async {
        guard let healthKitService else { return }

        do {
            try await healthKitService.requestAuthorization()

            // Always attempt the fetch — HealthKit doesn't report authorization status,
            // and a denied/empty fetch degrades gracefully to nil metrics.
            let snapshot = try await healthKitService.fetchTodaySnapshot()

            // Merge screen time from App Group shared UserDefaults (nil on the free tier).
            if let screenTimeService, let screenMinutes = screenTimeService.fetchTodayScreenTime() {
                snapshot.screenTimeMinutes = screenMinutes
            }

            todayHealth = snapshot
            // Only persist when there's real data — avoid storing empty snapshots.
            if snapshot.hasAnyMetric || snapshot.screenTimeMinutes != nil {
                persistHealthSnapshot(snapshot, context: context)
            }
        } catch {
            // Health data is non-critical; silently degrade
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

    var userName: String {
        userProfile?.displayName ?? "there"
    }
}
