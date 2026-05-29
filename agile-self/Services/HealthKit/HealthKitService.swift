//
//  HealthKitService.swift
//  agile-self
//
//  HealthKit integration for reading daily health aggregates.
//  Read-only access -- this service never writes to HealthKit.
//

import Foundation
import HealthKit

/// Provides read-only access to HealthKit data for building daily HealthSnapshot models.
///
/// Important privacy considerations:
/// - Only daily aggregates are fetched; raw samples are never stored.
/// - Authorization denial is handled gracefully (returns nil values).
/// - `HKHealthStore.isHealthDataAvailable()` is checked before any operation.
@Observable
final class HealthKitService {

    // MARK: - Properties

    /// Whether at least one HealthKit metric was readable on the most recent fetch.
    /// HealthKit does not expose read-authorization status, so this is inferred from data.
    var isAuthorized = false

    /// Whether the HealthKit authorization prompt has been requested this session.
    private(set) var hasRequestedAuthorization = false

    /// Whether HealthKit data is available on this device.
    nonisolated var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// The underlying HealthKit store. Nil if HealthKit is not available on this device.
    private nonisolated let healthStore: HKHealthStore?

    // MARK: - Read Types

    /// The set of HealthKit data types we request read access to.
    private nonisolated var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let calories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(calories)
        }
        if let exercise = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exercise)
        }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(heartRate)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        return types
    }

    // MARK: - Initialization

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }

    // MARK: - Authorization

    /// Requests read-only authorization for all supported HealthKit data types.
    /// Authorization denial is handled gracefully -- the app continues with nil health values.
    func requestAuthorization() async throws {
        guard let healthStore else { return }
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        // Requesting only means the prompt was shown — HealthKit does NOT reveal whether
        // read access was granted. `isAuthorized` is inferred from actual fetch results
        // instead (see fetchTodaySnapshot).
        hasRequestedAuthorization = true
    }

    // MARK: - Data Fetching

    /// Fetches today's health data and builds a HealthSnapshot.
    /// Returns a snapshot with nil values for any unavailable metrics.
    func fetchTodaySnapshot() async throws -> HealthSnapshot {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return HealthSnapshot(date: startOfDay)
        }

        async let sleepMinutes = fetchSleepMinutes(start: startOfDay, end: endOfDay)
        async let steps = fetchCumulativeQuantity(
            identifier: .stepCount,
            unit: .count(),
            start: startOfDay,
            end: endOfDay
        )
        async let activeCalories = fetchCumulativeQuantity(
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            start: startOfDay,
            end: endOfDay
        )
        async let exerciseMinutes = fetchCumulativeQuantity(
            identifier: .appleExerciseTime,
            unit: .minute(),
            start: startOfDay,
            end: endOfDay
        )
        async let restingHeartRate = fetchMostRecentQuantity(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            start: startOfDay,
            end: endOfDay
        )
        async let runningDistance = fetchCumulativeQuantity(
            identifier: .distanceWalkingRunning,
            unit: .meter(),
            start: startOfDay,
            end: endOfDay
        )

        let sleep = try await sleepMinutes
        let stepsValue = try await steps
        let caloriesValue = try await activeCalories
        let exerciseValue = try await exerciseMinutes
        let heartRateValue = try await restingHeartRate
        let distanceValue = try await runningDistance

        let snapshot = HealthSnapshot(
            date: startOfDay,
            sleepMinutes: sleep,
            steps: stepsValue.map { Int($0) },
            activeCalories: caloriesValue.map { Int($0) },
            exerciseMinutes: exerciseValue.map { Int($0) },
            restingHeartRate: heartRateValue.map { Int($0) },
            runningDistanceMeters: distanceValue
        )
        // HealthKit never reports read-authorization status, so infer access from whether
        // any metric returned data. Denial / no data → isAuthorized stays false, UI degrades.
        isAuthorized = snapshot.hasAnyMetric
        return snapshot
    }

    // MARK: - Private Helpers

    /// Fetches cumulative sum for a quantity type over a date range.
    private nonisolated func fetchCumulativeQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        guard let healthStore,
              let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = statistics?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    /// Fetches the most recent sample for a quantity type over a date range.
    private nonisolated func fetchMostRecentQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        guard let healthStore,
              let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    /// Fetches total sleep duration in minutes using sleep analysis samples.
    /// Only counts `asleepUnspecified`, `asleepCore`, `asleepDeep`, and `asleepREM` categories.
    private nonisolated func fetchSleepMinutes(start: Date, end: Date) async throws -> Int? {
        guard let healthStore,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        // Look back to the previous evening for sleep that ended today
        let calendar = Calendar.current
        let sleepStart = calendar.date(byAdding: .hour, value: -12, to: start) ?? start
        let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: end, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter to actual sleep states (not inBed)
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                ]

                let totalSeconds = categorySamples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                let totalMinutes = Int(totalSeconds / 60.0)
                continuation.resume(returning: totalMinutes > 0 ? totalMinutes : nil)
            }
            healthStore.execute(query)
        }
    }
}
