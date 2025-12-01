//
//  HealthKitManager.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import Foundation
import HealthKit

/// Manager for reading health data from HealthKit
@MainActor
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private nonisolated let healthStore: HKHealthStore?

    // MARK: - Authorization State

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var isLoading: Bool = false

    // MARK: - Today's Health Data

    private(set) var todaySteps: Int?
    private(set) var todaySleepMinutes: Int?
    private(set) var todayActiveCalories: Int?
    private(set) var todayExerciseMinutes: Int?
    private(set) var todayStandHours: Int?

    // MARK: - Data Types

    private nonisolated let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()

        // Activity
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        if let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(calorieType)
        }
        if let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseType)
        }
        if let standType = HKQuantityType.quantityType(forIdentifier: .appleStandTime) {
            types.insert(standType)
        }

        // Sleep
        types.insert(HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!)

        return types
    }()

    // MARK: - Init

    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
            self.authorizationStatus = .unavailable
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard let healthStore = healthStore else {
            authorizationStatus = .unavailable
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run {
                self.authorizationStatus = .authorized
            }
            await fetchTodayData()
        } catch {
            await MainActor.run {
                self.authorizationStatus = .denied
            }
            print("HealthKit authorization failed: \(error)")
        }
    }

    // MARK: - Fetch Today's Data

    @MainActor
    func fetchTodayData() async {
        guard healthStore != nil, authorizationStatus == .authorized else { return }

        isLoading = true
        defer { isLoading = false }

        async let steps = fetchTodaySteps()
        async let sleep = fetchLastNightSleep()
        async let calories = fetchTodayActiveCalories()
        async let exercise = fetchTodayExerciseMinutes()
        async let stand = fetchTodayStandHours()

        let (stepsResult, sleepResult, caloriesResult, exerciseResult, standResult) =
            await (steps, sleep, calories, exercise, stand)

        todaySteps = stepsResult
        todaySleepMinutes = sleepResult
        todayActiveCalories = caloriesResult
        todayExerciseMinutes = exerciseResult
        todayStandHours = standResult
    }

    // MARK: - Individual Fetches

    private func fetchTodaySteps() async -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }
        return await fetchTodaySum(for: stepType, unit: .count())
    }

    private func fetchTodayActiveCalories() async -> Int? {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return nil }
        return await fetchTodaySum(for: calorieType, unit: .kilocalorie())
    }

    private func fetchTodayExerciseMinutes() async -> Int? {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return nil }
        return await fetchTodaySum(for: exerciseType, unit: .minute())
    }

    private func fetchTodayStandHours() async -> Int? {
        guard let standType = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else { return nil }
        let minutes = await fetchTodaySum(for: standType, unit: .minute())
        return minutes.map { $0 / 60 }  // Convert to hours
    }

    private func fetchLastNightSleep() async -> Int? {
        guard let healthStore = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let calendar = Calendar.current
        let now = Date()

        // Get yesterday 6pm to today 12pm as sleep window
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let startOfSleepWindow = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday),
              let endOfSleepWindow = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfSleepWindow,
            end: endOfSleepWindow,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard error == nil,
                      let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Only count asleep states (not inBed)
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let totalSeconds = sleepSamples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                let minutes = Int(totalSeconds / 60)
                continuation.resume(returning: minutes > 0 ? minutes : nil)
            }
            healthStore.execute(query)
        }
    }

    private func fetchTodaySum(for quantityType: HKQuantityType, unit: HKUnit) async -> Int? {
        guard let healthStore = healthStore else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard error == nil,
                      let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = Int(sum.doubleValue(for: unit))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Period Data

    func fetchHealthSummary(from startDate: Date, to endDate: Date) async -> HealthSummary? {
        guard healthStore != nil, authorizationStatus == .authorized else { return nil }

        let days = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)

        async let steps = fetchPeriodAverage(
            type: .stepCount,
            unit: .count(),
            from: startDate,
            to: endDate,
            days: days
        )
        async let calories = fetchPeriodAverage(
            type: .activeEnergyBurned,
            unit: .kilocalorie(),
            from: startDate,
            to: endDate,
            days: days
        )
        async let exercise = fetchPeriodSum(
            type: .appleExerciseTime,
            unit: .minute(),
            from: startDate,
            to: endDate
        )
        async let sleep = fetchPeriodAverageSleep(from: startDate, to: endDate, days: days)

        let (avgSteps, avgCalories, totalExercise, avgSleep) =
            await (steps, calories, exercise, sleep)

        return HealthSummary(
            periodStart: startDate,
            periodEnd: endDate,
            avgSleepMinutes: avgSleep,
            avgSteps: avgSteps,
            totalExerciseMinutes: totalExercise,
            avgActiveCalories: avgCalories
        )
    }

    private func fetchPeriodAverage(
        type: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from startDate: Date,
        to endDate: Date,
        days: Int
    ) async -> Int? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type),
              let healthStore = healthStore else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard error == nil,
                      let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let total = Int(sum.doubleValue(for: unit))
                let average = total / days
                continuation.resume(returning: average)
            }
            healthStore.execute(query)
        }
    }

    private func fetchPeriodSum(
        type: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from startDate: Date,
        to endDate: Date
    ) async -> Int? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type),
              let healthStore = healthStore else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard error == nil,
                      let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: Int(sum.doubleValue(for: unit)))
            }
            healthStore.execute(query)
        }
    }

    private func fetchPeriodAverageSleep(from startDate: Date, to endDate: Date, days: Int) async -> Int? {
        guard let healthStore = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard error == nil,
                      let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let totalSeconds = sleepSamples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                let totalMinutes = Int(totalSeconds / 60)
                let avgMinutes = totalMinutes / days
                continuation.resume(returning: avgMinutes > 0 ? avgMinutes : nil)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Formatted Values

    var formattedTodaySteps: String {
        guard let steps = todaySteps else { return "--" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "--"
    }

    var formattedTodaySleep: String {
        guard let minutes = todaySleepMinutes else { return "--" }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    var formattedTodayCalories: String {
        guard let calories = todayActiveCalories else { return "--" }
        return "\(calories)"
    }

    var formattedTodayExercise: String {
        guard let minutes = todayExerciseMinutes else { return "--" }
        return "\(minutes)m"
    }
}
