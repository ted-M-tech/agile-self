//
//  AnalyticsService.swift
//  agile-self
//
//  Trend calculation, correlation detection, and data aggregation service.
//

import Foundation

// MARK: - Supporting Types

/// Summary statistics for a week of check-ins.
struct WeeklyStats {
    let averageComposite: Double
    let averageEnergy: Double
    let averageFocus: Double
    let averageStress: Double
    let averageGrowth: Double
    let bestDay: Date?
    let worstDay: Date?
    let checkInCount: Int
    let trend: Double  // Positive = improving, negative = declining
}

// MARK: - Analytics Service

/// Computes trends, averages, correlations, and statistics from check-in and health data.
final class AnalyticsService {

    // MARK: - Composite Score Trend

    /// Returns a time series of (date, composite score) pairs, sorted chronologically.
    nonisolated func compositeScoreTrend(checkIns: [DailyCheckIn]) -> [(Date, Double)] {
        checkIns
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.compositeScore) }
    }

    // MARK: - Dimension Averages

    /// Computes the average score for a given dimension across the provided check-ins.
    nonisolated func dimensionAverage(checkIns: [DailyCheckIn], dimension: DimensionType) -> Double {
        guard !checkIns.isEmpty else { return 0 }
        let total = checkIns.map { Double($0.score(for: dimension)) }.reduce(0, +)
        return total / Double(checkIns.count)
    }

    // MARK: - Correlation Detection

    /// Detects correlations between health metrics and check-in scores.
    ///
    /// Uses Pearson correlation coefficient on matched date pairs.
    /// Only returns correlations with |coefficient| >= 0.3 (weak or stronger).
    nonisolated func detectCorrelations(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) -> [Correlation] {
        guard checkIns.count >= 7, health.count >= 7 else { return [] }

        let calendar = Calendar.current

        // Index health snapshots by calendar day
        var healthByDay: [Date: HealthSnapshot] = [:]
        for snapshot in health {
            let day = calendar.startOfDay(for: snapshot.date)
            healthByDay[day] = snapshot
        }

        // Build matched pairs
        var matchedPairs: [(checkIn: DailyCheckIn, health: HealthSnapshot)] = []
        for checkIn in checkIns {
            let day = calendar.startOfDay(for: checkIn.date)
            if let snapshot = healthByDay[day] {
                matchedPairs.append((checkIn, snapshot))
            }
        }

        guard matchedPairs.count >= 5 else { return [] }

        var correlations: [Correlation] = []

        // Sleep vs Focus
        let sleepFocusPairs = matchedPairs.compactMap { pair -> (Double, Double)? in
            guard let sleep = pair.health.sleepMinutes else { return nil }
            return (Double(sleep), Double(pair.checkIn.focusScore))
        }
        if let coeff = pearsonCorrelation(sleepFocusPairs), abs(coeff) >= 0.3 {
            let direction = coeff > 0 ? "\u{2191}" : "\u{2193}"
            correlations.append(Correlation(
                factor1: "Sleep",
                factor2: "Focus",
                coefficient: coeff,
                description: "Sleep\(direction) = Focus\(direction)"
            ))
        }

        // Steps vs Energy
        let stepsEnergyPairs = matchedPairs.compactMap { pair -> (Double, Double)? in
            guard let steps = pair.health.steps else { return nil }
            return (Double(steps), Double(pair.checkIn.energyScore))
        }
        if let coeff = pearsonCorrelation(stepsEnergyPairs), abs(coeff) >= 0.3 {
            let direction = coeff > 0 ? "\u{2191}" : "\u{2193}"
            correlations.append(Correlation(
                factor1: "Steps",
                factor2: "Energy",
                coefficient: coeff,
                description: "Steps\(direction) = Energy\(direction)"
            ))
        }

        // Exercise vs Growth
        let exerciseGrowthPairs = matchedPairs.compactMap { pair -> (Double, Double)? in
            guard let exercise = pair.health.exerciseMinutes else { return nil }
            return (Double(exercise), Double(pair.checkIn.growthScore))
        }
        if let coeff = pearsonCorrelation(exerciseGrowthPairs), abs(coeff) >= 0.3 {
            let direction = coeff > 0 ? "\u{2191}" : "\u{2193}"
            correlations.append(Correlation(
                factor1: "Exercise",
                factor2: "Growth",
                coefficient: coeff,
                description: "Exercise\(direction) = Growth\(direction)"
            ))
        }

        // Screen Time vs Calm (stressScore stores Calm, high = calm/good). The Pearson
        // sign is computed from the real stored values, so the arrows stay correct after
        // the reframe (more screen time typically lowers calm → negative coefficient).
        let calmLabel = DimensionType.stress.label
        let screenCalmPairs = matchedPairs.compactMap { pair -> (Double, Double)? in
            guard let screen = pair.health.screenTimeMinutes else { return nil }
            return (Double(screen), Double(pair.checkIn.calmScore))
        }
        if let coeff = pearsonCorrelation(screenCalmPairs), abs(coeff) >= 0.3 {
            let calmDirection = coeff > 0 ? "\u{2191}" : "\u{2193}"
            correlations.append(Correlation(
                factor1: "Screen Time",
                factor2: calmLabel,
                coefficient: coeff,
                description: "Screen Time\u{2191} = \(calmLabel)\(calmDirection)"
            ))
        }

        // Resting Heart Rate vs Calm
        let hrCalmPairs = matchedPairs.compactMap { pair -> (Double, Double)? in
            guard let hr = pair.health.restingHeartRate else { return nil }
            return (Double(hr), Double(pair.checkIn.calmScore))
        }
        if let coeff = pearsonCorrelation(hrCalmPairs), abs(coeff) >= 0.3 {
            let calmDirection = coeff > 0 ? "\u{2191}" : "\u{2193}"
            correlations.append(Correlation(
                factor1: "Heart Rate",
                factor2: calmLabel,
                coefficient: coeff,
                description: "Heart Rate\u{2191} = \(calmLabel)\(calmDirection)"
            ))
        }

        // Running Distance vs Focus
        let runFocusPairs = matchedPairs.compactMap { pair -> (Double, Double)? in
            guard let dist = pair.health.runningDistanceMeters else { return nil }
            return (dist, Double(pair.checkIn.focusScore))
        }
        if let coeff = pearsonCorrelation(runFocusPairs), abs(coeff) >= 0.3 {
            let direction = coeff > 0 ? "\u{2191}" : "\u{2193}"
            correlations.append(Correlation(
                factor1: "Running",
                factor2: "Focus",
                coefficient: coeff,
                description: "Running\(direction) = Focus\(direction)"
            ))
        }

        // Sleep Score vs Composite Score
        let sleepScorePairs = matchedPairs.compactMap { pair -> (Double, Double)? in
            guard let score = pair.health.sleepScore else { return nil }
            return (Double(score), pair.checkIn.compositeScore)
        }
        if let coeff = pearsonCorrelation(sleepScorePairs), abs(coeff) >= 0.3 {
            let direction = coeff > 0 ? "\u{2191}" : "\u{2193}"
            correlations.append(Correlation(
                factor1: "Sleep Score",
                factor2: "Composite",
                coefficient: coeff,
                description: "Sleep Quality\(direction) = Overall Score\(direction)"
            ))
        }

        return correlations.sorted { abs($0.coefficient) > abs($1.coefficient) }
    }

    // MARK: - Weekly Stats

    /// Computes summary statistics for a set of check-ins (typically one week).
    nonisolated func weeklyStats(checkIns: [DailyCheckIn]) -> WeeklyStats {
        guard !checkIns.isEmpty else {
            return WeeklyStats(
                averageComposite: 0,
                averageEnergy: 0,
                averageFocus: 0,
                averageStress: 0,
                averageGrowth: 0,
                bestDay: nil,
                worstDay: nil,
                checkInCount: 0,
                trend: 0
            )
        }

        let sorted = checkIns.sorted { $0.date < $1.date }
        let count = Double(sorted.count)

        let avgComposite = sorted.map(\.compositeScore).reduce(0, +) / count
        let avgEnergy = sorted.map { Double($0.energyScore) }.reduce(0, +) / count
        let avgFocus = sorted.map { Double($0.focusScore) }.reduce(0, +) / count
        let avgStress = sorted.map { Double($0.stressScore) }.reduce(0, +) / count
        let avgGrowth = sorted.map { Double($0.growthScore) }.reduce(0, +) / count

        let bestDay = sorted.max(by: { $0.compositeScore < $1.compositeScore })?.date
        let worstDay = sorted.min(by: { $0.compositeScore < $1.compositeScore })?.date

        // Trend: compare first half vs second half
        let midpoint = sorted.count / 2
        let firstHalf = Array(sorted.prefix(max(midpoint, 1)))
        let secondHalf = Array(sorted.suffix(max(sorted.count - midpoint, 1)))

        let firstAvg = firstHalf.map(\.compositeScore).reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map(\.compositeScore).reduce(0, +) / Double(secondHalf.count)

        return WeeklyStats(
            averageComposite: avgComposite,
            averageEnergy: avgEnergy,
            averageFocus: avgFocus,
            averageStress: avgStress,
            averageGrowth: avgGrowth,
            bestDay: bestDay,
            worstDay: worstDay,
            checkInCount: sorted.count,
            trend: secondAvg - firstAvg
        )
    }

    // MARK: - Private Helpers

    /// Computes Pearson correlation coefficient for paired data.
    /// Returns nil if fewer than 3 data points.
    private nonisolated func pearsonCorrelation(_ pairs: [(Double, Double)]) -> Double? {
        guard pairs.count >= 3 else { return nil }

        let n = Double(pairs.count)
        let xs = pairs.map(\.0)
        let ys = pairs.map(\.1)

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
        let sumY2 = ys.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = ((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY)).squareRoot()

        guard denominator > 0 else { return nil }
        let r = numerator / denominator
        return r.isNaN ? nil : r
    }
}
